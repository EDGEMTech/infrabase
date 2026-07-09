# Copyright (c) 2025-2026 EDGEMTech SA

# Verdin-iMX8MP platform firmware staging — runs unconditionally for
# every verdin kernel build (bare bsp-linux / bare bsp-torizon / FC /
# dev-lvgl). The bake-in policy (CONFIG_EXTRA_FIRMWARE) is decided per
# config via Kconfig fragments (see e.g. meta-e1c-dev-lvgl's
# e1c-dev-lvgl-verdin.cfg) — this bbappend only ensures the blob is
# present on disk in the kernel work-tree so the build can find it
# when CONFIG_EXTRA_FIRMWARE references it.
#
# Why a separate nostamp task and not do_attach_infrabase:append:
# do_attach_infrabase is stamped, so when a capsule layer that adds a
# Kconfig fragment requiring extra firmware is layered into bblayers
# AFTER an initial unpack happened (or when switching capsules across
# builds), the appended copy code wouldn't re-run and the build would
# fail with "No rule to make target firmware/imx/sdma/sdma-imx7d.bin".
# Routing the copy through its own [nostamp] task makes it idempotent
# and re-applied on every invocation.

# Capture THISDIR at parse time with `:=` (immediate expansion) — at
# parse time THISDIR is the bbappend's directory, but inside the shell
# task body ${THISDIR} would re-expand to the BASE recipe's directory
# (meta-linux/recipes-linux/linux/) and the firmware path would resolve
# to meta-linux/recipes-bsp/... instead of meta-bsp/recipes-bsp/...
VERDIN_FIRMWARE_DIR := "${THISDIR}/../../recipes-bsp/bsp/verdin-imx8mp/firmware"

do_stage_verdin_firmware[nostamp] = "1"
do_stage_verdin_firmware () {
    install -d ${IB_TARGET}/firmware/imx/sdma
    install -m 0644 ${VERDIN_FIRMWARE_DIR}/imx/sdma/sdma-imx7d.bin \
        ${IB_TARGET}/firmware/imx/sdma/sdma-imx7d.bin
    install -d ${IB_TARGET}/firmware/mrvl
    install -m 0644 ${VERDIN_FIRMWARE_DIR}/mrvl/sdiouart8997_combo_v4.bin \
        ${IB_TARGET}/firmware/mrvl/sdiouart8997_combo_v4.bin
}

addtask do_stage_verdin_firmware after do_attach_infrabase before do_configure
