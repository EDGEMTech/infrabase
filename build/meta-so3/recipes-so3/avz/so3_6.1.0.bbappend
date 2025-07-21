
SUMMARY = "AVZ Hypervisor"
DESCRIPTION = "AVZ (Agency Virtualizer) hypervisor based on polymorphic SO3 Operating System"
LICENSE = "GPLv2"

inherit avz

# Version and revision
PN = "avz"
PR = "r0"
PV = "6.1.0"

OVERRIDES += ":avz"

# Where the working directory will be placed in infrabase root dir
IB_TARGET = "${IB_AVZ_PATH}"

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
	make ${IB_AVZ_CONFIG}
}

do_build () {
	echo "Building AVZ..."
	
	cd ${IB_TARGET} 
	make
}
