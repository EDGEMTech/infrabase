
SUMMARY = "Linux Board Support Package"
DESCRIPTION = "Linux Board Support Package (BSP) which builds the whole set of software components \
		to be deployed on the target hardware."

LICENSE = "GPLv2"

# Version and revision
PV = "1.0"
PR = "r0"

inherit filesystem
inherit linux
inherit logging
inherit bsp
inherit uboot 

OVERRIDES += ":linux"

IB_TARGET = "${IB_BSP_PATH}"

do_configure[noexec] = "1"
do_attach_infrabase[noexec] = "1"

include files/bsp_${IB_PLATFORM}.inc

# Building all components

do_build[depends] = "usr-linux:do_build uboot:do_build" 

addtask do_build
 
do_build () {
	bbplain "Everything built OK ..."
}

####################### Recipe to deploy everything

do_itb[nostamp] = "1"

do_itb () {

	if [ ! -f ${IB_ITB_PATH}/${IB_TARGET_ITS}.its ]; then
		bbfatal "No corresponding ITS found (${IB_TARGET_ITS})"
	else
		mkimage -f ${IB_ITB_PATH}/${IB_TARGET_ITS}.its ${IB_ITB_PATH}/${IB_TARGET_ITS}.itb
	fi
	
}

# Deploy everything

do_deploy[depends] = "filesystem:do_fs_check usr-linux:do_deploy uboot:do_deploy"
 
do_deploy[nostamp] = "1"
python do_deploy() {
    
    bb.plain("Deploy Linux boot (u-boot, itb)")

    __do_deploy_boot(d);
}

addtask do_itb before do_deploy
addtask do_deploy

do_deploy_boot[nostamp] = "1"
do_deploy_boot[depends] = "filesystem:do_fs_check"

python do_deploy_boot() {

    bb.plain("Deploy Linux boot (u-boot, itb)")

    __do_deploy_boot(d)
}
addtask do_itb before do_deploy_boot
addtask do_deploy_boot

do_attach_infrabase () {

	mkdir -p ${FILE_DIRNAME}/files/${IB_PLATFORM}
	ln -fs ${FILE_DIRNAME}/files/${IB_PLATFORM} ${IB_TARGET}
    
}

do_clean[depends] = "usr-linux:do_clean linux:do_clean uboot:do_clean"
do_clean[nostamp] = "1"
do_clean () {
	rm -f ${TMPDIR}/stamps/bsp-linux*
}
addtask do_clean
