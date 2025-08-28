
SUMMARY = "User space applications for SO3"
DESCRIPTION = "All (SO3) user space custom applications which take place in the rootfs of SO3"
LICENSE = "GPLv2"

inherit usr
  
# Release and version
PR = "r0"
PV = "1.0"

OVERRIDES += ":so3"

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_DIR}/so3/usr"

IB_TOOLCHAIN_FILE_PATH = "${IB_TARGET}/${IB_PLAT_CPU}_toolchain.cmake"

do_build[nostamp] = "1"
do_build[depends] = "rootfs-so3:do_build"
do_unpack[depends] += "so3:do_build"

do_configure[noexec] = "1"

do_deploy[depends] = "rootfs-so3:do_build"
do_deploy[nostamp] = "1"

# Deploy the usr contents, i.e. the deploy/ dir, in the SO3 rootfs
python do_deploy() {
    import subprocess
    import os
    
    d.setVar('ROOTFS_FILENAME', '')

    __do_rootfs_mount(d)
    
    src_dir = os.path.join(d.getVar('IB_TARGET'), 'build', 'deploy')
    dst_dir = os.path.join(d.getVar('IB_ROOTFS_PATH'), 'fs')
    
    cmd = f"sudo cp -r {src_dir}/. {dst_dir}/"
    print(cmd)
    result = subprocess.run(cmd, shell=True, check=True)
    
    __do_rootfs_umount(d)
    
}
 
addtask do_deploy
do_deploy[nostamp] = "1"

usr_os_build () {

	bbplain "Nothing at the moment"
	
}

# Installation of the user space components

do_usr_install_apps () {

        # All ELF applications available in usr

        usr_do_install_file_dir "${IB_TARGET}/build/src/*.elf" .

        usr_do_install_file_dir "${IB_TARGET}/out/*" .
}

do_usr_clean:append () {
    rm -f ${TMPDIR}/stamps/usr-so3*
}

