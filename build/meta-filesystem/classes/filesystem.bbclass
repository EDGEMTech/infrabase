###################################################################
#
#   The filesystem creation class
#   IB_STORAGE = soft create .img disk image
#   Prepares a flashable filesystem image containing
#   two partitions one for the bootloader and one for the rootfs
#   using losetup(8) to mount the image on a loop device  /dev/loopXX
#
#   IB_STORAGE = hard write to a real disk device
#   Writes to actual disk device, please double check config!
#
#   this class is inherited by platform-specific filesystem creation
#   classes init_storage_XX
#
#   Also see the IB_STORAGE_*, IB_ROOTFS_*
#   options in local.conf
#
#   Copyright (c) 2014-2023 REDS Institute, HEIG-VD
#   Copyright (c) 2023-2025 EDGEMTech Ltd
#
#   Authors:
#       EDGEMTech Ltd, Daniel Rossier (daniel.rossier@edgemtech.ch)
#       EDGEMTech Ltd, Erik Tagirov (erik.tagirov@edgemtech.ch)
#
###################################################################

inherit logging
inherit utils

inherit fs_${IB_PLATFORM}

IB_FILESYSTEM_PATH = "${IB_DIR}/filesystem"

def __do_main_umount(d, directory):
    import os

    IB_FILESYSTEM_PATH = d.getVar('IB_FILESYSTEM_PATH')

    directory = f"{IB_FILESYSTEM_PATH}/work/p{partition_number}"

    if os.path.ismount(directory):
        # TODO: use ionotify(7)
        while True:

            # Check if the source directory is still mounted
            if not os.path.ismount(directory):
                break

            os.sync()
            time.sleep(1)

            # Unmount the source directory
            os.system(f"umount '{directory}'")

    else:
        bb.warn(f"{directory} wasn't mounted - will remove mount point dir")

    # Remove the mountpoint dir and the symlink in the fs staging area
    os.system(f"rm -rf '{directory}'")
    os.system(f"rm '{IB_FILESYSTEM_PATH}/p{partition_number}'")

    utils_restore_user_ownership(d)

python do_fs_mount () {
    __do_fs_mount(d)
}

python do_fs_init_storage () {
    __do_fs_init_storage(d)
}

python do_fs_umount() {
    __do_fs_umount(d)
}

python do_fs_check () {
    __do_fs_check(d)
}

addtask do_fs_init_storage
addtask do_fs_check
addtask do_fs_mount
addtask do_fs_umount

# nostamp is necessary to let the user re-run this tasks many times
# on demand from scripts

do_fs_check[nostamp] = "1"
do_fs_init_storage[nostamp] = "1"
do_fs_mount[nostamp] = "1"
do_fs_umount[nostamp] = "1"


