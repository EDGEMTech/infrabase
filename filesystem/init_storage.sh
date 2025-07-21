#!/bin/bash

cd ../build 
source env.sh

bitbake filesystem -c fs_init_storage $1
cd ..
