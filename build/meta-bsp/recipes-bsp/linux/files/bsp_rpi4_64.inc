
# Deployment on RPi4_64 (64-bit) platform

require bsp_arm_common.inc

def __do_platform_deploy(d):

    import os
    import shutil
    import subprocess

    print("Platorm " + d.getVar('IB_PLATFORM'))

    subprocess.run(['sudo', 'cp -r',
        os.path.join(d.getVar('FILE_DIRNAME'), "../bsp/rpi4"),
        os.path.join(d.getVar('IB_FILESYSTEM_PATH'), "p1")])

    subprocess.run(['sudo', 'cp',
        os.path.join(d.getVar('IB_UBOOT_PATH'), "u-boot.bin"),
        os.path.join(d.getVar('IB_FILESYSTEM_PATH'), "p1/kernel8.img")])


    __deploy_arm_common(d)
