#!/bin/sh

mkdir -p ../inst/include
cp -r vtk${R_ARCH}/include/vtk/* ../inst/include/
rm -fr vtk-src
rm -f vtk-src.tar.gz