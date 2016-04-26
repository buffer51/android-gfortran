#!/bin/bash

# This script creates alternative archives without sysroot/ from standalone toolchains.

# Reads from out/dist/, outputs to out/releases/
if [ ! -d out/releases ]
then
    mkdir out/releases
fi

cd out/dist

# Clean potential tmp/ folder
if [ -d tmp ]
then
    rm -fr tmp;
fi

for x in `ls`;
do
    if [ -d tmp ]
    then
        rm -fr tmp
    fi

    # Extract the toolchain
    mkdir tmp
    cd tmp
    tar xvf ../$x;

    # Find the toolchain name
    TOOLCHAIN=`ls`

    # Standalone toolchain
    tar cvf ../../releases/$TOOLCHAIN-standalone.tar.bz2 $TOOLCHAIN

    # Toolchain without sysroot/
    rm -fr $TOOLCHAIN/sysroot
    tar cvf ../../releases/$TOOLCHAIN.tar.bz2 $TOOLCHAIN

    cd ..
    rm -fr tmp
done
