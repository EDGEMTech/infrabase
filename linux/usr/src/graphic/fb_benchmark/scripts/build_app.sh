#!/bin/bash

cd /app
cmake -B build-arm64 -S . \
      -DCMAKE_CXX_FLAGS="-O3" \
      -DCMAKE_C_FLAGS="-g -O0" \
      -DCMAKE_BUILD_TYPE=Release

# -DCMAKE_C_FLAGS="-I/usr/include/libdrm" \
make -j -C build-arm64
