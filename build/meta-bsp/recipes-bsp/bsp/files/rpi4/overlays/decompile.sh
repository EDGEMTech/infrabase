#!/bin/bash

for f in ./*.dtbo
do 
    dtc -I dtb -O dts $f -o ${f}.dts 
done