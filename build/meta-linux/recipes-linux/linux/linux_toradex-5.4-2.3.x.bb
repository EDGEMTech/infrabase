# Copyright (c) 2025-2026 EDGEMTech SA

SUMMARY = "Linux Operating System"
DESCRIPTION = "Linux OS with Toradex patches to run Colibri family boards"
LICENSE = "GPLv2"

# Release and version
PR = "imx"
PV = "toradex-5.4-2.3.x"

inherit linux

# The commit SHA
SRCREV = "49e4130e2197bd79e232faa746a449d167335778"
 
SRC_URI = "git://git.toradex.com/linux-toradex.git;branch=toradex_5.4-2.3.x-imx"
 
# Set of patches to be applied

FILESPATH:prepend: := "${THISDIR}/files/0005-${PF}:"

require files/0005-${PF}-patches.inc

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_LINUX_PATH}"
