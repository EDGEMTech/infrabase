
SUMMARY = "ATF firmware"
DESCRIPTION = "ARM Trusted Firmware (ATF)"

LICENSE = "GPLv2"

inherit atf

# Version and revision
PR = "r0"
PV = "1.5"
 
SRCREV = "2fa8c6349e9a1d965757d44f05a6c72687850b77"

SRC_URI = "git://git.toradex.com/imx-atf.git;branch=toradex_imx_5.4.70_2.3.0;protocol=https"
	
# To force the task to be re-executed
do_build[nostamp] = "1"
do_configure[noexec] = "1"
 
# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_ATF_PATH}"

do_build () {

	# Currently, only imx8_colibri is supported.
	
	if [ "${IB_PLATFORM}" = "imx8_colibri" ]; then
		do_build_bl31
	fi
}
