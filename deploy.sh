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
  echo "    -t    Deploy U-boot only"
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
    r)
      deploy_rootfs=y
      ;;
    s)
      deploy_so3=y
      ;;
    t)
      deploy_uboot=y
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

cd build
source env.sh

if [ "$deploy_all" ]; then
    bitbake bsp-linux -c deploy ${VERBOSE}
fi

if [ "$deploy_boot" ]; then
    bitbake bsp-linux -c deploy_boot ${VERBOSE}
fi

if [ "$deploy_so3" ]; then
    bitbake bsp-so3 -c deploy ${VERBOSE}
fi

if [ "$deploy_rootfs" ]; then
    bitbake rootfs-linux -c deploy ${VERBOSE}
fi

if [ "$deploy_usr" ]; then
    bitbake usr-linux -c deploy ${VERBOSE}
fi

if [ "$deploy_capsules" ]; then
    bitbake bsp-capsules -c deploy ${VERBOSE}
fi

if [ "$deploy_uboot" ]; then
    bitbake uboot -c deploy ${VERBOSE}
fi

