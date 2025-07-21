
SUMMARY = "SO3 kernel"
DESCRIPTION = "Smart Object Oriented Operating System"
LICENSE = "GPLv2"

inherit so3

# Version and revision
PR = "r0"
PV = "6.1.0"

OVERRIDES += ":so3"

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_SO3_PATH}"

SRCREV = "3b9fe41a85ed62df673d6295271fbd9c1e94648a"

SRC_URI = "git://github.com/smartobjectoriented/so3.git;branch=main;protocol=https"

do_configure () {
	cd ${IB_SO3_PATH}/so3
	make ${IB_SO3_CONFIG}
}

do_build () {
	echo "Building SO3..."
	
	cd ${IB_SO3_PATH}/so3
	make
}
