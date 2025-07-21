
SUMMARY = "Linux Operating System"
DESCRIPTION = "Linux OS used as main domain running on the embedded platform"
LICENSE = "GPLv2"

# Revision and version
PR = "r0"
PV = "6.12"

OVERRIDES += ":linux"

inherit linux

SRC_URI = "https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.12.tar.gz;protocol=https"

SRC_URI[sha256sum] = "1376ce98485a0c8de4635d0bfb88760924e4a818c0439d830738bb1c690b7ca4"

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_LINUX_PATH}"

do_configure () {
	cd ${IB_TARGET}
	make ${IB_LINUX_CONFIG}
}

do_build () {
	echo "Building Linux with ${CORES} cores..."
	
	cd ${IB_TARGET}

	make -j${CORES} Image
	  
	# Compile the device tree files
	make dtbs

}
 