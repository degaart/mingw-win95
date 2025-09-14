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
    https://ftpmirror.gnu.org/gnu/binutils/binutils-2.45.tar.xz \
    https://ftpmirror.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz \
    https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz \
    https://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz \
    https://ftpmirror.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz \
    https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v13.0.0.tar.bz2 \
)

for url in ${TARBALLS[@]}
do
    TARBALL="${url##*/}"
    if ! [ -f "$STATEDIR/${TARBALL}-downloaded" ]; then
        wget -c -P "$TARBALLSDIR" -T 60 "$url"
    fi
    touch "$STATEDIR/${TARBALL}-downloaded"
done

mkdir -p "$BUILDDIR"

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
        -disable-multilib \
        --disable-nls \
        --enable-lto \
        --disable-gdb > "$STATEDIR/binutils-configure.log" 2>&1
    then
        tail "$STATEDIR/binutils-configure.log"
        exit 1
    fi

    echo "Building binutils"
    if ! make -j$(nproc) > "$STATEDIR/binutils-build.log" 2>&1; then
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
if ! extract mingw-w64-v13.0.0.tar.bz2 MINGW_EXTRACT_DIR > "$STATEDIR/mingw-headers-extract.log" 2>&1; then
    tail "$STATEDIR/mingw-headers-extract.log"
    exit 1
fi

if ! checkstate mingw-w64-installed; then
    echo "Configuring mingw-w64-headers"
    if ! "$MINGW_EXTRACT_DIR/mingw-w64-headers/configure" \
        --host="$ARCH" \
        --prefix="$PREFIX" \
        --with-default-win32-winnt=0x0400 \
        --with-default-msvcrt=msvcrt-os \
        --prefix="$PREFIX/$ARCH" > "$STATEDIR/mingw-headers.log" 2>&1
    then
        tail "$STATEDIR/mingw-headers-build.log"
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
        --enable-threads=win32 \
        --disable-sjlj-exceptions \
        --with-dwarf2 > "$STATEDIR/gcc-phase1-configure.log" 2>&1
    then
        tail "$STATEDIR/gcc-phase1-configure.log"
        exit 1
    fi

    echo "Building gcc-phase1"
    if ! make -j$(nproc) all-gcc > "$STATEDIR/gcc-phase1-build.log" 2>&1; then
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
    rm -rf "$BUILDDIR/${MINGW_EXTRACT_DIR}-build"
    mkdir -p "$BUILDDIR/${MINGW_EXTRACT_DIR}-build"
    cd "$BUILDDIR/${MINGW_EXTRACT_DIR}-build"
    if ! "$MINGW_EXTRACT_DIR/mingw-w64-crt/configure" \
        --host="$ARCH" \
        --prefix="$PREFIX/$ARCH" \
        --with-default-msvcrt=msvcrt-os \
        --with-sysroot="$PREFIX/$ARCH" \
        --enable-lib32 \
        --disable-lib64 > "$STATEDIR/mingw-crt-configure.log" 2>&1
    then
        tail "$STATEDIR/mingw-crt-configure.log"
        exit 1
    fi

    echo "Building mingw-w64-crt"
    if ! make -j$(nproc) > "$STATEDIR/mingw-crt-build.log" 2>&1; then
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

### gcc (phase 2)
if ! checkstate gcc-phase2-installed; then
    cd "${GCC_EXTRACT_DIR}-build"

    echo "Building gcc-phase2"
    if ! make -j$(nproc) > "$STATEDIR/gcc-phase2-build.log" 2>&1; then
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

