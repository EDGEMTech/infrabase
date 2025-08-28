SUMMARY = "LVGL Library for SO3"
DESCRIPTION = "LVGL SO3 with framebuffer"
LICENSE = "MIT"

# Fetch LVGL

SRCREV = "c033a98afddd65aaafeebea625382a94020fe4a7"

SRC_URI = "git://github.com/lvgl/lvgl.git;branch=release/v9.3;protocol=https"

# These patches contain lv_port_linux patch
FILESPATH:prepend = "${THISDIR}/../lvgl/files/0001-${PF}:"

#require files/0001-${PF}-patches.inc

# To obtain the LVGL library in SO3, we need to fetch the submodule
# as defined in the SO3 git repository

python do_handle_fetch_git() {

    import os
    import subprocess

    # Now fetch the submodule to get lvgl within the usr/lib
    bb.plain("Now, copying LVGL at the right place ...")

    gitdir = os.path.join(d.getVar('WORKDIR'), 'git')

    # Move to the workdir of SO3

    target_dir = d.getVar('S')
    dst_dir = os.path.join(target_dir, 'lib', 'lvgl')
  
    # Fetch the submodules using full path
    cmd = f"cp -r {gitdir}/* {dst_dir}/"
    result = subprocess.run(cmd, shell=True, check=True)
} 

do_clean:append () {
     rm -rf ${IB_TARGET}/lib/lvgl/*
     rm -rf ${S}/lib/lvgl/*
}
