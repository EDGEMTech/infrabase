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
  echo "    -c    Clean generated files and structures for the recipe indicated as second argument"
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
      build_clean=y
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
    if [ "$build_clean" ]; then
      if [ "$build_so3" ]; then
        bitbake bsp-so3 -c clean
      else
        bitbake bsp-linux -c clean
      fi
    
    else

      if [ "$build_so3" ]; then
        bitbake bsp-so3 ${VERBOSE}
      else
        bitbake bsp-linux ${VERBOSE}
      fi
    fi
fi

if [ "$build_filesystem" ]; then

      printf "\n *** NOTE: *** Filesystem creation requires root access\n"
      printf "to be able to mount/umount and access loop devices, you may\n"
      printf "be prompted for the password\n\n"

      bitbake_path=$(which bitbake)

      sudo -E $bitbake_path filesystem ${VERBOSE}
fi

if [ "$build_uboot" ]; then
    if [ "$build_clean" ]; then
      bitbake uboot -c clean
    else
      bitbake uboot ${VERBOSE}
    fi
fi

if [ "$build_linux" ]; then

    if [ "$build_clean" ]; then
      bitbake linux -c clean
    else
      bitbake linux ${VERBOSE}
    fi
fi

if [ "$build_qemu" ]; then
    if [ "$build_clean" ]; then
      bitbake qemu -c clean
    else
      bitbake qemu ${VERBOSE}
    fi
fi

if [ "$build_rootfs" ]; then

    if [ "$build_clean" ]; then
      bitbake rootfs-linux -c clean
    else
      bitbake rootfs-linux ${VERBOSE}
    fi
fi

if [ "$build_usr" ]; then
    if [ "$build_clean" ]; then
      bitbake usr-linux -c clean
    else
      bitbake usr-linux ${VERBOSE}
    fi
fi

if [ "$build_avz" ]; then
    if [ "$build_clean" ]; then
      bitbake avz -c clean
    else
      bitbake avz ${VERBOSE}
    fi
fi

 if [ "$build_so3" ]; then
    if [ "$build_clean" ]; then
      bitbake bsp-so3 -c clean
    else
      bitbake bsp-so3 ${VERBOSE} 
    fi
  fi
