
SUMMARY = "Linux Operating System"
DESCRIPTION = "Linux OS used as main domain running on the embedded platform"
LICENSE = "GPLv2"

# Revision and version
PR = "r0"
PV = "6.12-rpi4"

OVERRIDES += ":linux"

inherit linux

SRC_URI = "https://github.com/raspberrypi/linux/archive/refs/heads/rpi-6.12.y.zip;protocol=https"

SRC_URI[sha256sum] = "f28ba6ca9cdbd9ae099133bb9772a0c6601a6dd729d0ba7ea9e50b08abb213a2"

# Set of patches to be applied

# These patches contain rpi4 64-bits enhancement
FILESPATH:prepend = "${THISDIR}/files/0001-${PF}:"
 
require files/0001-${PF}-patches.inc

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_LINUX_PATH}"

# Since the file is unzipped to a special name, we rename
# to the right name following bitbake convention
do_attach_infrabase:prepend() {
	rm -rf ${S}
	mv ${WORKDIR}/linux-rpi-6.12.y ${S}
}

do_configure[nostamp] = "1"
do_configure () {
	cd ${IB_TARGET}
	make ${IB_CONFIG} 
}

do_build () {
	echo "Building Linux with ${CORES} cores..."
	
	cd ${IB_TARGET}
	
	make -j${CORES} Image  
	    
	# Compile the device tree files
	make dtbs
	 
}

do_clean[nostamp] = "1"
do_clean () {
	rm -f ${TMPDIR}/stamps/linux*
	
	cd ${IB_TARGET}
	if [ -f .config ]; then
        	make distclean
    	fi
}
addtask do_clean
