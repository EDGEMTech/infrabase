#!/bin/bash

function usage {
  echo "$0 [OPTIONS]"
  echo "  -c        Clean"
  echo "  -v        Verbose"
  echo "  -h        Print this help"
}

clean=n
verbose=n

while getopts cdhvs option
  do
    case "${option}"
      in
        c) clean=y;;
	    v) verbose=y;;
        h) usage && exit 1;;
    esac
  done

cd ../../build
source env.sh

if [ $clean == y ]; then
  echo "Cleaning Linux usr"
  
  rm tmp/stamps/usr-linux*

  if [ $verbose == y ]; then
    bitbake usr-linux -c clean -vDDD
    exit 0
  fi

  bitbake usr-linux -c clean
  exit 0
fi

 echo "Building Linux usr"

if [ $verbose == y ]; then
    bitbake usr-linux -vDDD
    exit 0
fi

bitbake usr-linux



