# android-gfortran

## Introduction

This repository is intended as a tutorial for building the **GNU toolchain on
Android**, with support for **Fortran**. Prebuilt versions can be found
in the [Releases](https://github.com/buffer51/android-gfortran/releases) section.

It is based on my experience building
[OpenBLAS](https://github.com/xianyi/OpenBLAS) with LAPACK for Android
and on several other sources, including
[this stackoverflow post](http://stackoverflow.com/questions/13072751/compiling-android-ndk-with-objective-c-enabled-gcc-errors)
and [this Google group](https://groups.google.com/forum/#!msg/android-ndk/QR1qiN0jIpE/g0MHkhTd4YMJ).

## Procedure

The whole process has become fairly easy, thanks to the new Python building
scripts. A few modifications are still required, and the building process takes time.

### Goals & environment

This tutorial aims at building the **GNU toolchain 4.9** with **Android NDK r12b**.
It has been tested on Linux x86_64, but I expect that it should work with
small changes on other systems supported by the NDK.

### Windows

Although the NDK supports Windows (32-bit & 64-bit variants), the
toochain can only be built from Linux. The process is the roughly the
same, with a few extra steps detailed along the way.

### Steps

#### Requirements
A few tools are required for building the toolchain, namely:
- **git**
- **repo**
- **make**
- **gcc**
- **g++**
- **m4**
- **texinfo**
- **bison**
- **flex**

On Debian-based Linux, you can run:
```
sudo apt-get install git repo make gcc g++ m4 texinfo bison flex
```

**Note:** When building the toolchain for Windows, **mingw-w64** is required.
For 32-bit, **gcc-multilib** and **g++-multilib** are also needed.

#### Android NDK

The easiest way to setup all required sources is to follow the official steps
([found here](https://android.googlesource.com/toolchain/gcc/+/master/README.md)).

In this repository, call:
```
repo init -u https://android.googlesource.com/platform/manifest -b gcc
```

You can then use `repo sync` to clone all parts of the toolchain,
and `repo forall -c git checkout ndk-r12b` to checkout the r12b version.

#### Adding support for Fortran

In `toolchain/gcc/build-gcc.sh`, find the line that contains:
```
ENABLE_LANGUAGES="c,c++"
```
and replace it with:
```
ENABLE_LANGUAGES="c,c++,fortran"
```

To prevent a link-time error for `ttyname_r`, disable it in
`toolchain/gcc/gcc-4.9/libgfortran/configure` by commenting out the line:
```
as_fn_append ac_func_list " ttyname_r"
```

#### Building

If you are planning to build the ARM or AArch64 toolchains for Linux 64-bit
or Windows 32-bit, that shoule be sufficient.
Simply call `build.py` under `toolchain/gcc` which will take care of everything.
You can specify which toolchain to build. For instance:
```
./build.py --toolchain arm-linux-androideabi
```
See `./build.py -h` for possible values.
If nothing is specified, it will build all of them.

When building the toolchain for Windows, add `--host windows`
(or `--host windows64` for 64-bit).

#### Other targets / hosts

When building the **x86 or x86_64 toolchains**, additional changes are
required. There is an issue in libgfortran for the x86 and x86_64 targets
(see [#2](https://github.com/buffer51/android-gfortran/issues/2)
and [this issue](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=71363))
causing an error when building it. See the `x86.diff`.

When building the toolchain for **Windows 64-bit**,
you need to change `toolchain/binutils/binutils-2.25/gold/aarch64.cc`
(see [#1](https://github.com/buffer51/android-gfortran/issues/1)
and [this issue](https://sourceware.org/ml/binutils-cvs/2015-07/msg00148.html)).
Find line 2028 that says:
```
Insntype adr_insn = adrp_insn & ((1 << 31) - 1);
```
and replace it by:
```
Insntype adr_insn = adrp_insn & ((1u << 31) - 1);
```

### Deploying

The generated toolchain are not standalone as few includes are packaged.
This is because NDK lets you choose which platform version and which STL
you want to use.

To allow `ndk-build` to use your new toolchain, extract the archive
under `ndk/toolchains/$(TOOLCHAIN)/prebuilt/$(HOST_ARCH)`.
Don't forget to back up the toolchain that was already packaged with the NDK.
**Warning:** This refers to the full NDK downloadable from Google,
not the directory created by repo.

For instance, on Linux x86_64 for the AArch64 toolchain, unpack the archive as
`ndk/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64`.

If you want to create a **standalone toolchains** (i.e. you're not
using `ndk-build`), do the previous step, and then follow
[this guide](https://developer.android.com/ndk/guides/standalone_toolchain.html).
