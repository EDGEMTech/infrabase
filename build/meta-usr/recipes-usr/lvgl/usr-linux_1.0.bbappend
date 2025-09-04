SUMMARY = "LVGL Library for Linux"
DESCRIPTION = "LVGL Linux port"
LICENSE = "MIT"

# Fetch LVGL

SRCREV = "e9b4a18331c6087ac01fcd17f026ec2f0b1f2bc8"

LVGL_URI = "git://github.com/lvgl/lv_port_linux.git;branch=master;protocol=https"

SRC_URI += " ${@ d.expand(d.getVar('LVGL_URI') or '') \
                 if 'lvgl' in (d.getVar('OVERRIDES') or '').split(':') else '' }"
 
# These patches bring lv_port_linux/lvgl in the usr structure
FILESPATH:prepend = "${THISDIR}/../lvgl/files/0001-${PF}:"

require files/0001-${PF}-patches.inc

# Prepare to set up lv_port_linux in our user space environment

# Once the lv_port_linux git has been fetched, we pursue
# with the retrieval of the LVGL submodule
# Then, we move all the git contents in the consolidated working directory

python do_handle_fetch_git() {

    import os
    import subprocess
     
    ovrs = (d.getVar('OVERRIDES') or '').replace(' ', '').split(':')
    if 'lvgl' not in ovrs:
        return
    
    # Now fetch the submodule to get lvgl within lv_port_linux
    bb.plain("Now, fetching submodule for lv_port_linux ...")

    gitdir = os.path.join(d.getVar('WORKDIR'), 'git')

    # Fetch the submodules using full path
    subprocess.check_call(
        ['git', '-C', gitdir, 'submodule', 'update', '--init', '--recursive']
    )

    # Then, copy the full git directory to the {S} directory

    target_dir = d.getVar('S')

    # Make sure the target directory exists
    cmd = f"mkdir -p {target_dir}/src/lvgl/lv_port_linux"
    result = subprocess.run(cmd, shell=True, check=True)

    dst_dir = os.path.join(target_dir, 'src', 'lvgl', 'lv_port_linux')

    cmd = f"find . -not -path '*/.git/*' -and \( -type f -or -type d -empty \) -exec cp -r --parents -t {dst_dir} {{}} +"
    result = subprocess.run(cmd, shell=True, check=True, cwd=gitdir)
    
}

# Install the lvglsim application into the deploy directory
do_install_apps:append () {

    if echo ":${OVERRIDES}:" | grep -q ":lvgl"; then
        # Installation of the deploy/ content
        usr_do_install_file_root "${IB_TARGET}/build/src/graphic/drm-utils/drm-info"
        usr_do_install_file_root "${IB_TARGET}/build/src/graphic/drm_tool/drm_tool"
    
        usr_do_install_file_root "${IB_TARGET}/build/src/graphic/kmscube/kmscube"
        usr_do_install_file_root "${IB_TARGET}/build/src/graphic/gbmtest/gbmtest"
        usr_do_install_file_root "${IB_TARGET}/build/src/graphic/fb_benchmark/fb_benchmark"

        usr_do_install_file_root "${IB_TARGET}/build/bin/lvglsim"         
    fi
}

do_clean:append () {
   
    if echo ":${OVERRIDES}:" | grep -q ":lvgl"; then
      
        rm -rf ${IB_TARGET}/src/lvgl
        rm -rf ${IB_TARGET}/src/graphic
        cp ${IB_TARGET}.back/src/CMakeLists.txt ${IB_TARGET}/src/
    
        rm -rf ${S}

        rm -rf ${WORKDIR}/git
    fi
}