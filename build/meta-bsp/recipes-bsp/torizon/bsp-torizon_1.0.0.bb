# Copyright (c) 2025-2026 EDGEMTech SA

SUMMARY = "Deploy U-Boot and the uEnv config file"
DESCRIPTION = "Copies U-Boot to the mounted fs image and patches the uEnv with the ostree deployment id"

LICENSE = "GPLv2"

PV = "7.3.0"
PR = "r0"

inherit logging
inherit uboot
inherit fs_${IB_PLATFORM}
inherit rootfs
inherit bsp

# Platform-specific deploy logic. e1c-relevant platforms (verdin-imx8mp,
# virt64) live in meta-e1c/recipes-e1c/common/; the rest stay in meta-bsp.

include recipes-e1c/common/bsp_${IB_PLATFORM}.inc
include recipes-bsp/bsp/files/bsp_${IB_PLATFORM}.inc

OVERRIDES += ":torizon"
COMPATIBLE_PLATFORM = "verdin-imx8mp|virt64"

do_deploy[depends] = "filesystem:do_fs_check"

do_itb[nostamp] = "1"

# do_itb patches the Torizon initramfs and /incbin/'s the kernel Image —
# both must exist by the time it runs. linux:do_build is already in
# do_itb[depends] via bsp_${IB_PLATFORM}.inc; the Torizon dep is added
# here since "needs Torizon initramfs" is specific to bsp-torizon.

do_itb[depends] += "torizon:do_build"

do_deploy[nostamp] = "1"
python do_deploy() {

    bb.plain("Deploy Torizon env.")

    __do_deploy_boot(d);
}

# Wire do_itb before both do_build (so `build.sh -a` produces the
# .itb artefacts) and do_deploy (so a standalone `deploy.sh -a` still
# triggers the assembly through sstate misses).
addtask do_itb before do_build before do_deploy
addtask do_deploy

do_build[depends] += "uboot:do_build torizon:do_build"
do_build() {
	bbplain "All TorizonOS BSP deps were built"

}

deltask do_attach_infrabase
deltask do_configure

do_clean[depends] = "uboot:do_clean torizon:do_clean"
do_clean[nostamp] = "1"
do_clean () {
	rm -f ${TMPDIR}/stamps/bsp-torizon*
}
addtask do_clean
