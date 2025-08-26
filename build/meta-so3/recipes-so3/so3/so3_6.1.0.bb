
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

# Until the current MR of so3 repository is merged, we use the commit of the branch
SRC_URI = "git://github.com/smartobjectoriented/so3.git;branch=180-adaptation-for-avz-support;protocol=https"
SRCREV = "678603a318ad6d0043b0aed7fc106ba402c417bc"

# SRC_URI = "git://github.com/smartobjectoriented/so3.git;branch=main;protocol=https"
# SRCREV = "3b9fe41a85ed62df673d6295271fbd9c1e94648a"

do_configure[nostamp] = "1"
do_configure () {
	cd ${IB_SO3_PATH}/so3
	make ${IB_CONFIG}
}

do_build () {
	echo "Building SO3..."
	
	cd ${IB_SO3_PATH}/so3
	make
}
