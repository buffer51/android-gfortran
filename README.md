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
scripts Google added in NDK r11c. A few modifications are still required,
and the building process takes time.

### Goals & environment

This tutorial aims at building the **GNU toolchain 4.9** with **Android NDK r11c**.
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
- **make**
- **gcc**
- **g++**
- **m4**
- **texinfo**
- **bison**
- **flex**

(I also use **wget** to download the Android NDK).

On Debian-based Linux, you can run:
```
sudo apt-get install git make gcc g++ m4 texinfo bison flex wget
```

**Note:** When building the toolchain for Windows, **mingw-w64** is required.
For 32-bit, **gcc-multilib** and **g++-multilib** are also needed.

#### Android NDK

Download the Android NDK r11c from Google, and extract it.
It is best to rename the folder `ndk/` for building scripts to work
out-of-the-box.
```
wget http://dl.google.com/android/repository/android-ndk-r11c-linux-x86_64.zip
unzip android-ndk-r11c-linux-x86_64.zip
rm android-ndk-r11c-linux-x86_64.zip
mv android-ndk-r11c ndk
```

#### GNU toolchain

The next step is to download the GNU toolchain components from Google
repositories. We'll clone them in a folder called `toolchain/`.
```
mkdir toolchain && cd toolchain
git clone -b ndk-r11c https://android.googlesource.com/toolchain/gcc
git clone -b ndk-r11c https://android.googlesource.com/toolchain/build
git clone -b ndk-r11c https://android.googlesource.com/toolchain/gmp
git clone -b ndk-r11c https://android.googlesource.com/toolchain/gdb
git clone -b ndk-r11c https://android.googlesource.com/toolchain/mpc
git clone -b ndk-r11c https://android.googlesource.com/toolchain/mpfr
git clone -b ndk-r11c https://android.googlesource.com/toolchain/expat
git clone -b ndk-r11c https://android.googlesource.com/toolchain/ppl
git clone -b ndk-r11c https://android.googlesource.com/toolchain/cloog
git clone -b ndk-r11c https://android.googlesource.com/toolchain/isl
git clone -b ndk-r11c https://android.googlesource.com/toolchain/sed
git clone -b ndk-r11c https://android.googlesource.com/toolchain/binutils
```

#### Add support for Fortran

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

The last change to do before building everything is in
`ndk/build/lib/build_support.py`. Change the line
```
prebuilt_ndk = 'prebuilts/ndk/current'
```
to
```
prebuilt_ndk = 'ndk'
```
so that the building script can find the `ndk/platforms` folder
correctly.

**Note:** When building the x86 or x86_64 toolchains, additional changes are
required. There is an issue in libgfortran for the x86 and x86_64 targets
(see [this issue](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=71363)) causing
an error when building it. See the `x86.diff`.

**Note:** When building the toolchain for Windows,
you need to change `ndk/build/tools/prebuilt-common.sh` for the MinGW
wrapper to be found. Find the line that says:
```
# generate wrappers for BUILD toolchain
```
and replace the section that follows by:
```
LEGACY_TOOLCHAIN_PREFIX="/usr/bin/x86_64-linux-gnu-"
$NDK_BUILDTOOLS_PATH/gen-toolchain-wrapper.sh --src-prefix=i386-linux-gnu- \
        --cflags="-m32" --cxxflags="-m32" --ldflags="-m elf_i386" --asflags="--32" \
        --dst-prefix="$LEGACY_TOOLCHAIN_PREFIX" "$CROSS_WRAP_DIR"
$NDK_BUILDTOOLS_PATH/gen-toolchain-wrapper.sh --src-prefix=i386-pc-linux-gnu- \
        --cflags="-m32" --cxxflags="-m32" --ldflags="-m elf_i386" --asflags="--32" \
        --dst-prefix="$LEGACY_TOOLCHAIN_PREFIX" "$CROSS_WRAP_DIR"
# 64-bit BUILD toolchain.  libbfd is still built in 32-bit.
$NDK_BUILDTOOLS_PATH/gen-toolchain-wrapper.sh --src-prefix=x86_64-linux-gnu- \
        --dst-prefix="$LEGACY_TOOLCHAIN_PREFIX" "$CROSS_WRAP_DIR"
$NDK_BUILDTOOLS_PATH/gen-toolchain-wrapper.sh --src-prefix=x86_64-pc-linux-gnu- \
        --dst-prefix="$LEGACY_TOOLCHAIN_PREFIX" "$CROSS_WRAP_DIR"
```

**Note:** If you want to build **standalone toolchains**
(i.e. you're not using `ndk-build`), there is one extra step.
In `toolchain/gcc/build-gcc.sh`, comment out two lines:
```
run rm -rf "$TOOLCHAIN_INSTALL_PATH/sysroot"
```
and
```
rm -rf $TOOLCHAIN_INSTALL_PATH/sysroot
```

Now you can run `build.py` under `toolchain/gcc` which will take care of everything.
You can specify which toolchain to build. For instance:
```
./build.py --toolchain arm-linux-androideabi
```
See `./build.py -h` for possible values.
If nothing is specified, it will build all of them.

**Note:** When building the toolchain for Windows, add `--host windows`
(or `--host windows64` for 64-bit).

### Deploying

If you built a standalone toolchain, just extract the archive. You'll probably
want to add `$(TOOLCHAIN)/bin` to your path.

Otherwise, to allow `ndk-build` to use your new toolchain, extract the archive
under `ndk/toolchains/$(TOOLCHAIN)/prebuilt/$(HOST_ARCH)`. Don't forget to back up
the toolchain that was already packaged with the NDK.

For instance, on Linux x86_64 for the AArch64 toolchain, unpack the archive as
`ndk/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64`.
