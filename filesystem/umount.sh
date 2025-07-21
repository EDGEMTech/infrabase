#!/bin/bash

cd ../build
source env.sh

bitbake filesystem -c fs_umount  $1
cd ..
