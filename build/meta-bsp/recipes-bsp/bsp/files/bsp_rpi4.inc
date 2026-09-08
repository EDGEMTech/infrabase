# Copyright (c) 2025-2026 EDGEMTech SA

# Deployment on RPi4 (32-bit) platform.
#
# No __do_platform_boot_chain: TF-A's rpi4 port is AArch64-only (BL31 is an
# armv8 binary loaded as the armstub), so this platform has the bare U-Boot
# chain and nothing else — and AVZ, being aarch64-only too, does not run
# here either. See build/conf/platforms.conf.

require bsp_arm_common.inc

def __do_platform_deploy(d):

    import os
    from bb.process import run

    print("Platform " + d.getVar('IB_PLATFORM'))

    filedirname = d.getVar('FILE_DIRNAME')
    dst = d.getVar('IB_FILESYSTEM_PATH')
    uboot_path = d.getVar('IB_UBOOT_PATH')

    run(f"cp -r {filedirname}/../bsp/rpi4/* {dst}/p1")

    # bsp/rpi4/config.txt is shared with the 64-bit BSP and deliberately holds
    # no arm_64bit/kernel setting; append the 32-bit half of the chain.
    # FILE_DIRNAME is the *recipe's* directory (recipes-bsp/linux), not this
    # include's — hence the ../bsp hop, as in the copy above.
    run(f"cat {filedirname}/../bsp/files/config_rpi4_arm32.txt >> {dst}/p1/config.txt")

    # 32-bit: the firmware loads the armv7 kernel as kernel7l.img on a Pi 4
    # (kernel8.img is the aarch64 name — see bsp_rpi4_64.inc).
    run(f"cp {uboot_path}/u-boot.bin {dst}/p1/kernel7l.img")

    __deploy_arm_common(d)
