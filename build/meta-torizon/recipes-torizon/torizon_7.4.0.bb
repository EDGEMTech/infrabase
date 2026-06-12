# Copyright (c) 2025-2026 EDGEMTech SA

SUMMARY = "Builds TorizonOS from source"
DESCRIPTION = "TorizonOS is located in the torizon subdirectory"

LICENSE = "GPLv2"

PV = "7.4.0"
PR = "r0"

inherit logging
inherit linux
inherit bsp

OVERRIDES += ":torizon"

# TorizonOS uses a custom tool to fetch everything
# There is no copying for now. (The dir is already present)

do_unpack[noexec] = "1"
do_fetch[noexec] = "1"
do_configure[noexec] = "1"
do_attach_infrabase[noexec] = "1"
do_build_torizon_os[depends] += "uboot:do_build"

torizon_env() {
	# Convert torizon subdir to abs path - otherwise, TorizonOS's Yocto
	# Rightfully complains about the '..' in build/../torizon_yocto

	bbwarn "IB_TORIZON_DIR_PATH = ${IB_TORIZON_DIR_PATH}"
	torizondir=$(cd "${IB_TORIZON_DIR_PATH}" && pwd)

	if [ ! -d $torizondir ]; then
		bbfatal "TorizonOS subdirectory: $torizondir does not exist"
	fi

	envscript=$torizondir/setup-environment
	builddir=$torizondir/build

}

do_build[shell] = "/bin/bash"

# This starts the TorizonOS build
# If building from scratch, it can take some time ~2h

do_build () {

    torizon_env
    cd $torizondir

    bbwarn "For machine ${IB_TORIZON_MACHINE_ID}"
    bbwarn "In torizondir: ${torizondir}"

    bash -c "
        set -e
        cd '$torizondir'

        MACHINE='${IB_TORIZON_MACHINE_ID}' \
        EULA=1 \
        IB_TOOLCHAIN_PATH='${IB_TOOLCHAIN_PATH}' \
        EDGEM_CI_YOCTO_SSTATE_DIR='${EDGEM_CI_YOCTO_SSTATE_DIR}' \
        EDGEM_CI_YOCTO_DL_DIR='${EDGEM_CI_YOCTO_DL_DIR}' \
        EDGEM_CI_YOCTO_CACHE_DIR='${EDGEM_CI_YOCTO_CACHE_DIR}' \
  
        source ./setup-environment build && bitbake torizon-docker
    "

    cd -
}
addtask do_build 

do_clean[nostamp] = "1"
do_clean () {

	torizon_env

	# Heavy-handed 'wipe all' - except the downloads
	rm -rf $builddir
	rm -rf $torizondir/sstate-cache
	rm -rf ${TMPDIR}/stamps/torizon*
	rm -f ${TMPDIR}/stamps/rootfs-torizon*
}
addtask do_clean
 