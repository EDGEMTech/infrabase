

# Copyright (c) 2023-2026 EDGEMTech Ltd

# Class for BSP - Main recipe

# The link to the firmwares of all boards
IB_BSP_PATH = "${IB_DIR}/build/meta-bsp/recipes-bsp/bsp"

# Standard tree locations for the boot-chain components. atf.bbclass sets
# the same values; kept here so do_deploy_boot_chain can assemble
# flash0.img / flash.bin.

IB_ATF_PATH = "${IB_DIR}/atf"
IB_OPTEE_PATH = "${IB_DIR}/atf/optee"

# Path to the ITB files

IB_ITB_PATH:linux = "${IB_DIR}/linux/target"

# This is the uEnv.txt file related to U-boot depending on the BSP
IB_UENV = "${FILE_DIRNAME}/files/uEnv_${IB_PLATFORM}.txt"

inherit logging
inherit filesystem

# Platform boot chain — produces the bootloader-side artefacts (flash0.img
# + FIP for virt64, flash.bin for verdin). Lives at the BSP class level so
# it is shared across every BSP recipe.
#
# Per-platform bootloader assembly lives in bsp_<platform>.inc as
# __do_platform_boot_chain(d).

# Boot-chain dependencies gate on IB_BOOT_CHAIN:
#   "uboot"      → only u-boot (no ATF, no OP-TEE pulled in)
#   "atf+uboot"  → ATF + u-boot, no OP-TEE
#   "full"       → ATF + OP-TEE + u-boot
#
# Deps are wired into BOTH do_build (so `build.sh -a` actually compiles
# every source artefact) AND do_deploy_boot_chain (so a standalone
# `deploy.sh -a` without a prior build still pulls them through sstate).

do_deploy_boot_chain[nostamp] = "1"
do_deploy_boot_chain[depends] = "uboot:do_build"

python () {
    chain = d.getVar('IB_BOOT_CHAIN') or ""
    extra = []
    if chain in ("atf+uboot", "full"):
        extra.append("atf:do_build")
    if chain == "full":
        extra.append("optee:do_build")
    if extra:
        deps = ' ' + ' '.join(extra)
        d.appendVarFlag('do_deploy_boot_chain', 'depends', deps)
        d.appendVarFlag('do_build', 'depends', deps)
}

python do_deploy_boot_chain () {
    plat = d.getVar('IB_PLATFORM') or '?'
    chain = d.getVar('IB_BOOT_CHAIN') or '?'
    bb.plain(f"Deploy boot chain for platform {plat} (chain={chain})")

    try:
        __do_platform_boot_chain(d)
    except NameError:
        bb.note(f"No __do_platform_boot_chain defined for {plat} — skipping")
}
addtask do_deploy_boot_chain before do_deploy

def __do_deploy_boot(d):

    if d.getVar('IB_STORAGE_MODE') not in ("remote", "http"):
        bb.warn("Now mounting")
        __do_fs_mount(d)

    __do_platform_deploy(d)

    if d.getVar('IB_STORAGE_MODE') not in ("remote", "http"):
        __do_fs_umount(d)
