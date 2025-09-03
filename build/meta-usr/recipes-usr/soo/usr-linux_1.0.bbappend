
SUMMARY = "Add-ons for SOO user space environment"
DESCRIPTION = "Additional applications are used to manage SO3 capsules"
LICENSE = "GPLv2"
 
# Installing usr apps mean to move the binary and all files which need to
# be copied to the rootfs. Be aware that it is a deploy directory and not
# the rootfs itself; this is achieved with the do_deploy task (by the bsp recipe)

do_install_apps:soo:append () {
   
    usr_do_install_file_root "${IB_TARGET}/build/src/soo/injector"
    usr_do_install_file_root "${IB_TARGET}/build/src/soo/restoreme"
    usr_do_install_file_root "${IB_TARGET}/build/src/soo/saveme"
    usr_do_install_file_root "${IB_TARGET}/build/src/soo/melist"
    usr_do_install_file_root "${IB_TARGET}/build/src/soo/shutdownme"
}
