
SUMMARY = "Linux Operating System running as guest on AVZ"
DESCRIPTION = "Linux OS used as main domain (agency) running on the embedded platform"
LICENSE = "GPLv2"

# These patches contain lv_port_linux patch
FILESEXTRAPATHS:linux-guest:prepend = "${THISDIR}/../linux-guest/files/0002-${PF}:"
 
require files/0002-${PF}-patches.inc

do_configure[nostamp] = "1"
do_configure:linux-guest () {
	cd ${IB_TARGET}
	make ${IB_CONFIG}
}

do_build:linux-guest () {
	echo "Building Linux with ${CORES} cores..."
	
	cd ${IB_TARGET}

	make -j${CORES} Image
	  
	# Compile the device tree files
	make dtbs
}
 
