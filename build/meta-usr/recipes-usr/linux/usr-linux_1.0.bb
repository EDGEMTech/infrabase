
SUMMARY = "User space applications for Linux"
DESCRIPTION = "All (Linux) user space custom applications which take place in the rootfs of Linux"
LICENSE = "GPLv2"

inherit usr
inherit linux
inherit filesystem
inherit rootfs

# Release and version
PR = "r0"
PV = "1.0"

OVERRIDES += ":linux"

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_DIR}/linux/usr"

IB_TOOLCHAIN_FILE_PATH = "${IB_ROOTFS_PATH}/host/share/buildroot/toolchainfile.cmake"

do_build[depends] = "rootfs-linux:do_build"
do_unpack[depends] += "linux:do_build"

do_configure[noexec] = "1"

do_deploy[depends] = "rootfs-linux:do_deploy"
do_deploy[nostamp] = "1"

# Deploy the usr contents, i.e. the deploy/ dir, in the corresponding partition of the filesystem
python do_deploy() {

    import os
 
    __do_fs_mount(d)
    
    IB_USR_PATH = d.getVar('IB_USR_PATH')
    IB_FILESYSTEM_PATH = d.getVar('IB_FILESYSTEM_PATH')
    IB_ROOTFS_PARTITION = d.getVar('IB_ROOTFS_PARTITION')

    if not os.path.isdir(os.path.join(IB_USR_PATH, "build", "deploy")):
     
        __do_fs_umount(d)
        bb.fatal("The {} does not exist; please build usr first...".format(IB_USR_PATH))

    if not os.path.isdir(os.path.join(IB_FILESYSTEM_PATH, IB_ROOTFS_PARTITION, "root")):
        __do_fs_umount(d)
        bb.fatal("The root directory is not present in the second partition; please deploy rootfs...")
      
 
    os.system("sudo cp -r {}/build/deploy/* {}/{}/".format(IB_USR_PATH, IB_FILESYSTEM_PATH, IB_ROOTFS_PARTITION))
	
    __do_fs_umount(d)
}
 
addtask do_deploy

# Build extra components which is not in src/ directory like modules
usr_os_build () {

	# Modules
 
	if [ ! -f ${IB_LINUX_PATH}/Module.symvers ]; then 
        	echo "Generating Module.symvers..." ; 
        	make -j${CORES} -C ${IB_LINUX_PATH} modules ; 
            make INSTALL_MOD_PATH=${IB_ROOTFS_PATH}/target -C ${IB_LINUX_PATH} modules_install ; \
    fi

	make -C ${IB_LINUX_PATH} M=${IB_TARGET}/src/modules modules
}	

# Installing usr apps mean to move the binary and all files which need to
# be copied to the rootfs. Be aware that it is a deploy directory and not
# the rootfs itself; this is achieved with the do_deploy task (by the bsp recipe)

do_usr_install_apps () {
    
    # Installation of the deploy/ content
    usr_do_install_file_root "${IB_TARGET}/build/src/graphic/drm-utils/drm-info"
    usr_do_install_file_root "${IB_TARGET}/build/src/graphic/drm_tool/drm_tool"
    
    usr_do_install_file_root "${IB_TARGET}/build/src/graphic/kmscube/kmscube"
    usr_do_install_file_root "${IB_TARGET}/build/src/graphic/gbmtest/gbmtest"
    usr_do_install_file_root "${IB_TARGET}/build/src/graphic/fb_benchmark/fb_benchmark"

    # Installation of modules if any
    
    usr_do_install_file_root "${IB_TARGET}/src/modules/*.ko"
}

usr_os_clean () {
	# Clean the modules
	make -C ${IB_LINUX_PATH} M=${IB_TARGET}/src/modules clean
}
