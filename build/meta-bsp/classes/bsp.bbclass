

# Copyright (c) 2023-2025 EDGEMTech Ltd

# Class for BSP - Main recipe

# The link to the firmwares of all boards
IB_BSP_PATH = "${IB_DIR}/build/meta-bsp/recipes-bsp/bsp"

# Path to the ITB files

IB_ITB_PATH:so3 = "${IB_DIR}/so3/target"
IB_ITB_PATH:linux = "${IB_DIR}/linux/target"

inherit logging
inherit filesystem

def __do_deploy_boot(d):

    if d.getVar('IB_STORAGE') != "remote":
        __do_fs_mount(d)

    __do_platform_deploy(d)

    if d.getVar('IB_STORAGE') != "remote":
        __do_fs_umount(d)

    utils_restore_user_ownership(d)
