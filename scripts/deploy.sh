#!/bin/bash

# General build script for the infrabase infrastructure.

# Copyright (c) 2014-2023 REDS Institute, HEIG-VD
# Copyright (c) 2023-2025 EDGEMTech

VERBOSE=""

usage()
{
  echo "Infrabase deployment script"
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Where OPTIONS are:"
  echo "  Components options:"
  echo "    -a    Deploy all"
  echo "    -b    Deploy boot components only (u-boot, kernel, dtb)"
  echo "    -c    Deploy SO3 capsules into the target"
  echo "    -r    Deploy rootfs (secondary)"
  echo "    -u    Deploy usr apps"
  echo "    -s    Deploy SO3"
  echo "    -o    Deploy U-boot only"
  echo "    -v    Build with log verbosity"
  echo

  exit 1
}

while getopts "abcrstuv" o; do
  case "$o" in
    a)
      deploy_all=y
      ;;
    b)
      deploy_boot=y
      ;;
    c)
      deploy_capsules=y
      ;;
    o)
      deploy_uboot=y
      ;;
    r)
      deploy_rootfs=y
      ;;
    s)
      deploy_so3=y
      ;;
    u)
      deploy_usr=y
      ;;
    v)
      VERBOSE="-vDDD"
      ;;
    *)
      usage
      ;;
  esac
done

if [ $OPTIND -eq 1 ]; then usage; fi

printf "\n*** NOTE: *** Deployment requires root access, to be able to mount/umount\n"
printf "and access loop devices, you may be prompted for the password\n\n"

cd build
source env.sh

bitbake_path=$(which bitbake)

if [ "$deploy_all" ]; then
    sudo -E $bitbake_path bsp-linux -c deploy ${VERBOSE}
fi

if [ "$deploy_boot" ]; then
    sudo -E $bitbake_path bsp-linux -c deploy_boot ${VERBOSE}
fi

if [ "$deploy_so3" ]; then
    sudo -E $bitbake_path bsp-so3 -c deploy ${VERBOSE}
fi

if [ "$deploy_rootfs" ]; then
    sudo -E $bitbake_path rootfs-linux -c deploy ${VERBOSE}
fi

if [ "$deploy_usr" ]; then
    sudo -E $bitbake_path usr-linux -c deploy ${VERBOSE}
fi

if [ "$deploy_capsules" ]; then
    sudo -E $bitbake_path bitbake bsp-capsules -c deploy ${VERBOSE}
fi

if [ "$deploy_uboot" ]; then
    sudo -E $bitbake_path bitbake uboot -c deploy ${VERBOSE}
fi

