require bsp_arm_common.inc

do_itb:torizon () {
	if [ ! -f ${IB_ITB_PATH}/${IB_TARGET_ITS}.its ]; then
		bbfatal "No corresponding ITS found for platform ${IB_PLATFORM}"
	else
		mkimage -f ${IB_ITB_PATH}/${IB_TARGET_ITS}.its ${IB_ITB_PATH}/${IB_TARGET_ITS}.itb
	fi
}


def __do_platform_deploy(d):

    print("Platorm " + d.getVar('IB_PLATFORM'))

    ovrs = (d.getVar('OVERRIDES') or '').replace(' ', '').split(':')

    # Are we in Torizon recipes?
    if 'torizon' not in ovrs:

        __deploy_arm_common(d)

    else:

        IB_UBOOT_PATH = d.getVar("IB_UBOOT_PATH")
        IB_PLATFORM = d.getVar("IB_PLATFORM")
        IB_ITB_PATH = d.getVar("IB_ITB_PATH")
        IB_FILESYSTEM_PATH = d.getVar("IB_FILESYSTEM_PATH")

        uenv_path = f"{IB_UBOOT_PATH}/uEnv.d/uEnv_{IB_PLATFORM}_torizon.txt"

        torizon_rootfs_ar_path = __torizon_rootfs_archive_path(d)
        filesys_path = f"{IB_FILESYSTEM_PATH}/p1"
        itb_path = f"{IB_ITB_PATH}/{IB_PLATFORM}_torizon.itb"

        cmd = (f"tar -tf {torizon_rootfs_ar_path} | grep ^\./ostree/boot.1.1 | "
            f"grep -o /[a-f0-9]*/$ | sed 's/\///g\'")

        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        deployment_id = res.stdout.strip()

        if not os.path.isfile(uenv_path):
            bb.fatal(uenv_path + " is missing ...")

        # Read the uEnv file perform the substitution
        with open(uenv_path) as uenv_file:
            uenv_content = uenv_file.read()
            uenv_file.close()

        uenv_content = uenv_content.replace("${OSTREE_DEPLOYMENT_ID}", deployment_id)

        if not os.path.isfile(itb_path):
            bb.fatal(itb_path + " is missing ...")

        try:
            with open(f"{filesys_path}/uEnv.txt", "w") as dest_uenv_file:
                dest_uenv_file.write(uenv_content)

        except Exception as e:
            __do_fs_umount(d)
            bb.fatal(f"An error has occurred: {e}")

        subprocess.run(["cp", itb_path, filesys_path])
