
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

SRC_URI = "git://github.com/smartobjectoriented/so3.git;branch=main;protocol=https"
SRCREV = "6077eb580d4aa7579fd27f57dbdf5f36b466415b"

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

do_clean[nostamp] = "1"
do_clean () {
	rm -f ${TMPDIR}/stamps/so3*
}
addtask do_clean
