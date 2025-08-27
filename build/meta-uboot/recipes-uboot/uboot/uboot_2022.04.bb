
SUMMARY = "U-boot Universal Bootloader"
DESCRIPTION = "U-boot bootloader receipt"
LICENSE = "GPLv2"

# Release and version
PR = "r0"
PV = "2022.04"

inherit uboot
inherit bsp

SRCREV = "e4b6ebd3de982ae7185dbf689a030e73fd06e0d2"

SRC_URI = "git://github.com/u-boot/u-boot;branch=master;protocol=https"

# Set of patches to be applied to get a version adapted with AVZ
# and adding various defconfig files.

FILESPATH:prepend = "${THISDIR}/files/0001-${PF}:"

require files/0001-${PF}-patches.inc
 
# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_UBOOT_PATH}"

# Future enhancement with ATF
# do_configure[depends] += "atf:do_build"
# do_configure[depends] += "bsp-linux:do_build_firmware"

# The following code is here as example, but actually currently not used
do_configure () {
	
	cd ${IB_TARGET}
	make ${IB_PLATFORM}_defconfig
	
	# Specific handling for bbb platform
	if [ "${IB_PLATFORM}" = "bbb" ]; then
	
		# If a disk image is used with BBB, it is intended to be
		# deployed in the eMMC, hence some different uEnv configurations
		
		if [ "${IB_STORAGE}" = "soft" ]; then
			ln -fs ${IB_UBOOT_PATH}/uEnv.d/uEnv_bbb_flash.txt ${IB_UBOOT_PATH}/uEnv.d/uEnv_bbb.txt 
		else
			ln -fs ${IB_UBOOT_PATH}/uEnv.d/uEnv_bbb_sd.txt ${IB_UBOOT_PATH}/uEnv.d/uEnv_bbb.txt 
		fi

	elif [ "${IB_PLATFORM}" = "imx8_colibri" ]; then

		ln -fs ${IB_ATF_PATH}/build/imx8qx/release/bl31.bin .
		echo "--> ${IB_BSP_PATH}"
		cp ${IB_BSP_PATH}/mx8qxc0-ahab-container.img mx8qx-ahab-container.img
		
	fi
	
}

do_build () {
	
	bbplain "Building U-boot with ${CORES} cores..."
	cd ${IB_TARGET}
	make -j${CORES}
}

def __do_deploy(d):

    WORKDIR = d.getVar("WORKDIR")

    bb.warn(("Deployment of U-boot is achieved in the BSP recipe"
        " since it strongly depends on the platform"))

    # This task runs as root - avoid creating temp files as root
    utils_restore_user_ownership(d)

python do_deploy () {
    __do_deploy(d)
}

do_deploy[nostamp] = "1"
addtask do_deploy
