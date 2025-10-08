#!/usr/bin/env bash

set -eou pipefail

BASEDIR="$(dirname "$0")"
pushd . > /dev/null
BASEDIR="$PWD"
popd > /dev/null

ARCH=i586-w64-mingw32
PREFIX="$BASEDIR/$ARCH"
BUILDDIR="$BASEDIR/build"
TARBALLSDIR="$BASEDIR/tarballs"
STATEDIR="$BASEDIR/state"
#NPROC=$(nproc)
NPROC=8

export PATH="$PREFIX/bin:$PATH"

checkstate()
{
    local statename="$1"
    [ -f "$STATEDIR/$statename" ]
}

writestate()
{
    local statename="$1"
    touch "$STATEDIR/$statename"
}

extract()
{
    local tarball="$1"
    local __resultvar="$2"
    local basename="${tarball%.tar*}"

    printf -v "$__resultvar" "%s" "$BUILDDIR/$basename"

    if checkstate "{tarball}-extracted"; then
        cd "$BUILDDIR/${basename}-build"
        return 0
    fi

    if ! [ -d "$BUILDDIR/$basename" ]; then
        echo "Extracting $tarball"
        tar xf "$TARBALLSDIR/$tarball" -C "$BUILDDIR"
    fi

    if [ -d "$BUILDDIR/${basename}-build" ]; then
        rm -rf "$BUILDDIR/${basename}-build"
    fi
    mkdir "$BUILDDIR/${basename}-build"
    cd "$BUILDDIR/${basename}-build"

    writestate "${tarball}-extracted"
}

mkdir -p "$BUILDDIR"
mkdir -p "$TARBALLSDIR"
mkdir -p "$STATEDIR"

### Download tarballs
TARBALLS=( \
    "https://ftpmirror.gnu.org/gnu/binutils/binutils-2.45.tar.xz dee5b4267e0305a99a3c9d6131f45759" \
    "https://ftpmirror.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz b861b092bf1af683c46a8aa2e689a6fd" \
    "https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz 956dc04e864001a9c22429f761f2c283" \
    "https://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz 5c9bc658c9fd0f940e8e3e0f09530c62" \
    "https://ftpmirror.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz 7c32c39b8b6e3ae85f25156228156061" \
    "http://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2 11436d6b205e516635b666090b94ab32" \
    "https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v13.0.0.tar.bz2 b8c58e04a9cb8f2f9474e043ecad2f27" \
)

for line in "${TARBALLS[@]}"
do
    read -r url md5 <<< "$line"
    tarball="${url##*/}"

    if ! [ "$(md5sum "$TARBALLSDIR/$tarball" | awk '{print $1}')" = "$md5" ]; then
        wget -c -P "$TARBALLSDIR" -T 60 "$url"
    fi
done

mkdir -p "$BUILDDIR"

### gmp
if ! extract gmp-6.3.0.tar.xz GMP_EXTRACT_DIR > "$STATEDIR/gmp-extract.log" 2>&1; then
    tail "$STATEDIR/gmp-extract.log"
    exit 1
fi

if ! checkstate gmp-installed; then
    echo "Configuring gmp"
    if ! "$GMP_EXTRACT_DIR/configure" \
        --prefix="$PREFIX" \
        --enable-static \
        --disable-shared \
        > "$STATEDIR/gmp-configure.log" 2>&1
    then
        tail "$STATEDIR/gmp-configure.log"
        exit 1
    fi

    echo "Building gmp"
    if ! make -j$NPROC > "$STATEDIR/gmp-build.log" 2>&1; then
        tail "$STATEDIR/gmp-build.log"
        exit 1
    fi

    echo "Installing gmp"
    if ! make install > "$STATEDIR/gmp-install.log" 2>&1; then
        tail "$STATEDIR/gmp-install.log"
        exit 1
    fi
    writestate gmp-installed
fi

### mpfr
if ! extract mpfr-4.2.2.tar.xz MPFR_EXTRACT_DIR > "$STATEDIR/mpfr-extract.log" 2>&1; then
    tail "$STATEDIR/mpfr-extract.log"
    exit 1
fi

if ! checkstate mpfr-installed; then
    echo "Configuring mpfr"
    if ! "$MPFR_EXTRACT_DIR/configure" \
        --prefix="$PREFIX" \
        --enable-static \
        --disable-shared \
        --disable-dependency-tracking \
        --with-gmp="$PREFIX" \
        > "$STATEDIR/mpfr-configure.log" 2>&1
    then
        tail "$STATEDIR/mpfr-configure.log"
        exit 1
    fi

    echo "Building mpfr"
    if ! make -j$NPROC > "$STATEDIR/mpfr-build.log" 2>&1; then
        tail "$STATEDIR/mpfr-build.log"
        exit 1
    fi

    echo "Installing mpfr"
    if ! make install > "$STATEDIR/mpfr-install.log" 2>&1; then
        tail "$STATEDIR/mpfr-install.log"
        exit 1
    fi
    writestate mpfr-installed
fi

### mpc
if ! extract mpc-1.3.1.tar.gz MPC_EXTRACT_DIR > "$STATEDIR/mpc-extract.log" 2>&1; then
    tail "$STATEDIR/mpc-extrac.log"
    exit 1
fi

if ! checkstate mpc-installed; then
    echo "Configuring mpc"
    if ! "$MPC_EXTRACT_DIR/configure" \
        --prefix="$PREFIX" \
        --enable-static \
        --disable-shared \
        --disable-dependency-tracking \
        --with-gmp="$PREFIX" \
        --with-mpfr="$PREFIX" \
        > "$STATEDIR/mpc-configure.log" 2>&1
    then
        tail "$STATEDIR/mpc-configure.log"
        exit 1
    fi

    echo "Building mpc"
    if ! make -j$NPROC > "$STATEDIR/mpc-build.log" 2>&1; then
        tail "$STATEDIR/mpc-build.log"
        exit 1
    fi

    echo "Installing mpc"
    if ! make install > "$STATEDIR/mpc-install.log" 2>&1; then
        tail "$STATEDIR/mpc-install.log"
        exit 1
    fi
    writestate mpc-installed
fi

### isl
if ! extract isl-0.18.tar.bz2 ISL_EXTRACT_DIR > "$STATEDIR/isl-extract.log" 2>&1; then
    tail "$STATEDIR/isl-extract.log"
    exit 1
fi

if ! checkstate isl-installed; then
    echo "Configuring isl"
    if ! "$ISL_EXTRACT_DIR/configure" \
        --prefix="$PREFIX" \
        --enable-static \
        --disable-shared \
        --disable-dependency-tracking \
        --with-gmp-prefix="$PREFIX" \
        > "$STATEDIR/isl-configure.log" 2>&1
    then
        tail "$STATEDIR/isl-configure.log"
        exit 1
    fi

    echo "Building isl"
    if ! make -j$NPROC > "$STATEDIR/isl-build.log" 2>&1; then
        tail "$STATEDIR/isl-build.log"
        exit 1
    fi

    echo "Installing isl"
    if ! make install > "$STATEDIR/isl-install.log" 2>&1; then
        tail "$STATEDIR/isl-install.log"
        exit 1
    fi
    writestate isl-installed
fi

### binutils
if ! extract binutils-2.45.tar.xz BINUTILS_EXTRACT_DIR > "$STATEDIR/binutils-extract.log" 2>&1; then
    tail "$STATEDIR/binutils-extract.log"
    exit 1
fi

if ! checkstate binutils-installed; then
    echo "Configuring binutils"
    if ! "$BINUTILS_EXTRACT_DIR/configure" \
        --prefix="$PREFIX" \
        --disable-shared \
        --enable-static \
        --with-sysroot="$PREFIX"\
        --target="$ARCH" \
        --disable-multilib \
        --disable-nls \
        --enable-lto \
        --disable-gdb \
        --disable-werror \
        --enable-gold \
        --enable-ld \
        --disable-dependency-tracking \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --enable-plugins \
        --with-gmp="$PREFIX" \
        --with-mpc="$PREFIX" \
        --with-mpfr="$PREFIX" \
        --with-isl="$PREFIX" \
        --with-static-standard-libraries \
        > "$STATEDIR/binutils-configure.log" 2>&1
    then
        tail "$STATEDIR/binutils-configure.log"
        exit 1
    fi

    echo "Building binutils"
    if ! make -j$NPROC > "$STATEDIR/binutils-build.log" 2>&1; then
        tail "$STATEDIR/binutils-build.log"
        exit 1
    fi

    echo "Installing binutils"
    if ! make install > "$STATEDIR/binutils-install.log" 2>&1; then
        tail "$STATEDIR/binutils-install.log"
        exit 1
    fi
    writestate binutils-installed
fi

### mingw-w64 headers
if ! extract mingw-w64-v13.0.0.tar.bz2 MINGW_EXTRACT_DIR > "$STATEDIR/mingw-extract.log" 2>&1; then
    tail "$STATEDIR/mingw-extract.log"
    exit 1
fi

if ! checkstate mingw-w64-patched; then
    #patch -d "$MINGW_EXTRACT_DIR" -p1 < "$BASEDIR/patches/winpthreads-disable_debugger_check.diff"
    patch -d "$MINGW_EXTRACT_DIR" -p1 < "$BASEDIR/patches/winpthreads-pthread9x.diff"
    pushd . > /dev/null
    cd "$MINGW_EXTRACT_DIR/mingw-w64-libraries/winpthreads"
    autoreconf -i
    popd > /dev/null
    writestate mingw-w64-patched
fi

if ! checkstate mingw-w64-installed; then
    echo "Configuring mingw-w64-headers"
    if ! "$MINGW_EXTRACT_DIR/mingw-w64-headers/configure" \
        --host="$ARCH" \
        --with-default-win32-winnt=0x0400 \
        --with-default-msvcrt=msvcrt-os \
        --prefix="$PREFIX/mingw" \
        CFLAGS="-DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        CXXFLAGS="-DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        > "$STATEDIR/mingw-headers.log" 2>&1
    then
        tail "$STATEDIR/mingw-headers-build.log"
        exit 1
    fi

    echo "Building mingw-w64-headers"
    if ! make -j$NPROC > "$STATEDIR/mingw-headers-build.log" 2>&1; then
        tail "$STATEDIR/mingw-headers-build.log"
        exit 1
    fi

    echo "Installing mingw-w64-headers"
    if ! make install > "$STATEDIR/mingw-headers-install.log" 2>&1; then
        tail "$STATEDIR/mingw-headers-install.log"
        exit 1
    fi

    echo "Installing mingw-w64-headers"
    if ! make install > "$STATEDIR/mingw-headers-install.log" 2>&1; then
        tail "$STATEDIR/mingw-headers-install.log"
        exit 1
    fi
    writestate mingw-w64-installed
fi

### gcc (phase 1)
if ! extract gcc-15.2.0.tar.xz GCC_EXTRACT_DIR > "$STATEDIR/gcc-extract.log" 2>&1; then
    tail "$STATEDIR/gcc-extract.log"
    exit 1
fi

if ! checkstate gcc-patched; then
    patch -d "$GCC_EXTRACT_DIR" -p1 < "$BASEDIR/patches/gcc-remove_getthreadid.diff"
    writestate gcc-patched
fi

if ! checkstate gcc-phase1-installed; then
    echo "Configuring gcc-phase1"
    if ! "$GCC_EXTRACT_DIR/configure" \
        --target="$ARCH" \
        --disable-shared \
        --enable-static \
        --disable-multilib \
        --prefix="$PREFIX" \
        --enable-languages=c,c++ \
        --disable-nls \
        --enable-threads=posix \
        --disable-dependency-tracking \
        --with-pic \
        --enable-gold \
        --enable-ld \
        --enable-lto \
        --disable-bootstrap \
        --disable-libssp \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --with-gmp="$PREFIX" \
        --with-mpc="$PREFIX" \
        --with-mpfr="$PREFIX" \
        --with-isl="$PREFIX" \
        --with-sysroot="$PREFIX" \
        --with-build-sysroot="$PREFIX" \
        --with-as="$PREFIX/bin/${ARCH}-as" \
        --with-ld="$PREFIX/bin/${ARCH}-ld" \
        CFLAGS_FOR_TARGET="-Os -DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        CXXFLAGS_FOR_TARGET="-Os -DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        LDFLAGS_FOR_TARGET="-s" \
        > "$STATEDIR/gcc-phase1-configure.log" 2>&1
    then
        tail "$STATEDIR/gcc-phase1-configure.log"
        exit 1
    fi

    echo "Building gcc-phase1"
    if ! make -j$NPROC all-gcc > "$STATEDIR/gcc-phase1-build.log" 2>&1; then
        tail "$STATEDIR/gcc-phase1-build.log"
        exit 1
    fi

    echo "Installing gcc-phase1"
    if ! make install-gcc > "$STATEDIR/gcc-phase1-install.log" 2>&1; then
        tail "$STATEDIR/gcc-phase1-instaill.log"
        exit 1
    fi
    writestate gcc-phase1-installed
fi

### mingw-w64-crt
if ! checkstate mingw-w64-crt-installed; then
    echo "Configuring mingw-w64-crt"
    rm -rf "$BUILDDIR/mingw-w64-crt-build"
    mkdir -p "$BUILDDIR/mingw-w64-crt-build"
    cd "$BUILDDIR/mingw-w64-crt-build"
    if ! "$MINGW_EXTRACT_DIR/mingw-w64-crt/configure" \
        --host="$ARCH" \
        --prefix="$PREFIX/$ARCH" \
        --with-default-msvcrt=msvcrt-os \
        --with-sysroot="$PREFIX/$ARCH" \
        --enable-lib32 \
        --disable-lib64 \
        --disable-dependency-tracking \
        CFLAGS="-Os -DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        LDFLAGS="-s" \
        > "$STATEDIR/mingw-crt-configure.log" 2>&1
    then
        tail "$STATEDIR/mingw-crt-configure.log"
        exit 1
    fi

    echo "Building mingw-w64-crt"
    if ! make -j$NPROC > "$STATEDIR/mingw-crt-build.log" 2>&1; then
        tail "$STATEDIR/mingw-crt-build.log"
        exit 1
    fi

    echo "Installing mingw-w64-crt"
    if ! make install > "$STATEDIR/mingw-crt-install.log" 2>&1; then
        tail "$STATEDIR/mingw-crt-install.log"
        exit 1
    fi
    writestate mingw-w64-crt-installed
fi

### winpthreads
if ! checkstate winpthreads-installed; then
    echo "Configuring winpthreads"
    rm -rf "$BUILDDIR/winpthreads-build"
    mkdir -p "$BUILDDIR/winpthreads-build"
    cd "$BUILDDIR/winpthreads-build"
    if ! "$MINGW_EXTRACT_DIR/mingw-w64-libraries/winpthreads/configure" \
        --host="$ARCH" \
        --disable-shared \
        --enable-static \
        --prefix="$PREFIX/$ARCH" \
        CFLAGS="-Os -DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        LDFLAGS="-s" \
        > "$STATEDIR/winpthreads-configure.log" 2>&1
    then
        tail "$STATEDIR/winpthreads-configure.log"
        exit 1
    fi

    echo "Building winpthreads"
    if ! make -j$NPROC > "$STATEDIR/winpthreads-build.log" 2>&1; then
        tail "$STATEDIR/winpthreads-build.log"
        exit 1
    fi

    echo "Installing winpthreads"
    if ! make install > "$STATEDIR/winpthreads-install.log" 2>&1; then
        tail "$STATEDIR/winpthreads-install.log"
        exit 1
    fi

    writestate winpthread-installed
fi

### gcc (phase 2)
if ! checkstate gcc-phase2-installed; then
    rm -rf "${GCC_EXTRACT_DIR}-build"
    mkdir "${GCC_EXTRACT_DIR}-build"
    cd "${GCC_EXTRACT_DIR}-build"

    echo "Configuring gcc-phase2"
    if ! "$GCC_EXTRACT_DIR/configure" \
        --target="$ARCH" \
        --disable-shared \
        --enable-static \
        --disable-multilib \
        --prefix="$PREFIX" \
        --enable-languages=c,c++ \
        --disable-nls \
        --enable-threads=posix \
        --disable-dependency-tracking \
        --with-pic \
        --enable-gold \
        --enable-ld \
        --enable-lto \
        --disable-bootstrap \
        --disable-libssp \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --with-gmp="$PREFIX" \
        --with-mpc="$PREFIX" \
        --with-mpfr="$PREFIX" \
        --with-isl="$PREFIX" \
        --with-sysroot="$PREFIX" \
        --with-build-sysroot="$PREFIX" \
        --with-as="$PREFIX/bin/${ARCH}-as" \
        --with-ld="$PREFIX/bin/${ARCH}-ld" \
        CFLAGS_FOR_TARGET="-Os -DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        CXXFLAGS_FOR_TARGET="-Os -DWIN32_WINNT=0x0400 -DWINVER=0x0400" \
        LDFLAGS_FOR_TARGET="-s" \
        > "$STATEDIR/gcc-phase1-configure.log" 2>&1
    then
        tail "$STATEDIR/gcc-phase1-configure.log"
        exit 1
    fi

    echo "Building gcc-phase2"
    if ! make -j$NPROC > "$STATEDIR/gcc-phase2-build.log" 2>&1; then
        tail "$STATEDIR/gcc-phase2-build.log"
        exit 1
    fi

    echo "Installing gcc-phase2"
    if ! make install > "$STATEDIR/gcc-phase2-build.log" 2>&1; then
        tail "$STATEDIR/gcc-phase2-build.log"
        exit 1
    fi
    writestate gcc-phase2-installed
fi

