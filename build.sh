#!/bin/bash

# General build script for the infrabase infrastructure.

# Copyright (c) 2014-2023 REDS Institute, HEIG-VD
# Copyright (c) 2023-2025 EDGEMTech

VERBOSE=""

usage()
{
  echo "Infrabase build script"
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Where OPTIONS are:"
  echo "  Components options:"
  echo "    -a    Build all (pursuing the build is possible)"
  echo "    -b    Build U-boot"
  echo "    -c    By adding this option with another, it performs a fresh build (clean)"
  echo "    -f    Create and prepare the filesystem"
  echo "    -l    Build Linux"
  echo "    -q    Build QEMU with custom patches (framebuffer enabled)"
  echo "    -r    Build rootfs (pursuing the build if possible)"
  echo "    -s    Build SO3"
  echo "    -u    Build usr apps"
  echo "    -v    Build with log verbosity"
  echo "    -z    Build AVZ"
  echo

  exit 1
}

while IFS= read -r line; do
  # Check if the line starts with "IB_PLATFORM"
  if [[ $line == IB_PLATFORM* ]]; then
  	# Extract the value between the quotes
  	value=$(echo "$line" | awk -F'"' '{print $2}')
    
   	# Set the IB_PLATFORM variable to the extracted value
   	IB_PLATFORM="$value"
  	break
  fi     
done < build/conf/local.conf


echo "Platform = ${IB_PLATFORM}"

while getopts "abcflqrsuvz" o; do
  case "$o" in
    a)
      build_all=y
      ;;
    b)
      build_uboot=y
      ;;
    c)
      build_clear=y
      ;;
    f)
      build_filesystem=y
      ;;
    l)
      build_linux=y
      ;;
    q)
      build_qemu=y
      ;;
    r)
      build_rootfs=y
      ;;
    s)
      build_so3=y
      ;;
    u)
      build_usr=y
      ;;
    v)
      VERBOSE="-vDDD"
      ;;
    z)
      build_avz=y
      ;;
    *)
      usage
      ;;
  esac
done

if [ $OPTIND -eq 1 ]; then usage; fi

cd build
source env.sh

if [ "$build_all" ]; then
    if [ "$build_clear" ]; then
      if [ "$build_so3" ]; then
        rm -f tmp/stamps/bsp-so3*
        rm -f tmp/stamps/so3*
        rm -f tmp/stamps/usr-so3*
      else
        rm -f tmp/stamps/*
      fi
    fi

    if [ "$build_so3" ]; then
      bitbake bsp-so3 ${VERBOSE}
    else
      bitbake bsp-linux ${VERBOSE}
    fi
fi

if [ "$build_filesystem" ]; then
      bitbake filesystem ${VERBOSE}
fi

if [ "$build_uboot" ]; then
    if [ "$build_clear" ]; then
      rm -f tmp/stamps/uboot*
    fi

    rm -f tmp/stamps/uboot*

    bitbake uboot ${VERBOSE}
fi

if [ "$build_linux" ]; then

    if [ "$build_clear" ]; then
      rm -f tmp/stamps/linux*
    fi

    bitbake linux ${VERBOSE}
fi

if [ "$build_qemu" ]; then
    if [ "$build_clear" ]; then
      rm -f tmp/stamps/qemu*
    fi

    bitbake qemu ${VERBOSE}
fi

if [ "$build_rootfs" ]; then

    if [ "$build_clear" ]; then
      rm -f tmp/stamps/rootfs-linux*
      rm -f tmp/stamps/buildroot*
      bitbake rootfs-linux -c clean
    fi
    
    bitbake rootfs-linux ${VERBOSE}
fi

if [ "$build_usr" ]; then
    if [ "$build_clear" ]; then
      rm -f tmp/stamps/usr*
    fi

    bitbake usr-linux ${VERBOSE}
fi

if [ "$build_avz" ]; then
    if [ "$build_clear" ]; then
      rm -f tmp/stamps/avz*
    fi

    bitbake avz ${VERBOSE}
fi

 if [ "$build_so3" ]; then
    if [ "$build_clear" ]; then
        rm -f tmp/stamps/bsp-so3*
        rm -f tmp/stamps/so3*
        rm -f tmp/stamps/usr-so3*
    fi

    bitbake bsp-so3 ${VERBOSE} 
  fi
