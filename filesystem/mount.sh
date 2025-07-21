#!/bin/bash

cd ../build
source env.sh

bitbake filesystem -c fs_mount $1
cd ..
