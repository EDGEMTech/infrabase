SUMMARY = "LVGL Library for SO3"
DESCRIPTION = "LVGL SO3 with framebuffer"
LICENSE = "MIT"

inherit so3

# These patches contain lv_port_linux patch
FILESPATH:prepend = "${THISDIR}/../lvgl/files/0001-${PF}:"

#require files/0001-${PF}-patches.inc

# To obtain the LVGL library in SO3, we need to fetch the submodule
# as defined in the SO3 git repository

python do_handle_fetch_git() {

    import os
    import subprocess

    # Now fetch the submodule to get lvgl within the usr/lib
    bb.plain("Now, fetching submodule ...")

    # Move to the workdir of SO3

    gitdir = os.path.join(d.getVar('IB_SO3_PATH'), 'usr', 'lib', 'lvgl')
  
    # Fetch the submodules using full path
    subprocess.check_call(
        ['git', '-C', gitdir, 'submodule', 'update', '--init', '--recursive']
    )

    # Update the working usr directory so that do_attach_infrabase will copy everything.
    __retrieve_usr_dir(d)
} 
