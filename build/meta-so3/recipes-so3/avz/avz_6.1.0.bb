
SUMMARY = "AVZ Hypervisor"
DESCRIPTION = "AVZ (Agency Virtualizer) hypervisor based on polymorphic SO3 Operating System"
LICENSE = "GPLv2"

inherit avz

# Version and revision
 
PR = "r0"
PV = "6.1.0"

OVERRIDES += ":avz"

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_AVZ_PATH}"

SRC_URI = "git://github.com/smartobjectoriented/so3.git;branch=180-adaptation-for-avz-support;protocol=https"
SRCREV = "678603a318ad6d0043b0aed7fc106ba402c417bc"

# SRC_URI = "git://github.com/smartobjectoriented/so3.git;branch=main;protocol=https"
# SRCREV = "3b9fe41a85ed62df673d6295271fbd9c1e94648a"

python do_handle_fetch_git() {

    import os
    import subprocess

    # Copy only the SO3 kernel

    gitdir = os.path.join(d.getVar('WORKDIR'), 'git')
    dst_dir = d.getVar('S')

    cmd = f"cp -r {gitdir}/so3/. {dst_dir}/"

    result = subprocess.run(cmd, shell=True, check=True)
}

do_configure () {
	cd ${IB_TARGET}
	make ${IB_CONFIG}
}

do_build () {
	echo "Building AVZ..."
	
	cd ${IB_TARGET} 
	make
}

do_clean[nostamp] = "1"
do_clean () {
	rm -f ${TMPDIR}/stamps/avz*
}
addtask do_clean
