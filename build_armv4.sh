#!/bin/bash

set -e

WORK_DIR="/workspace/coreutils"
BUILD_DIR="${WORK_DIR}/build-mips"
OUTPUT_DIR="/workspace/build-output-mips"

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--output-dir <path>]"
            exit 1
            ;;
    esac
done

if ! OUTPUT_DIR=$(realpath "$OUTPUT_DIR" 2>/dev/null); then
    OUTPUT_DIR=$(cd "$OUTPUT_DIR"; pwd)
fi

OUTPUT_STRIPPED="${OUTPUT_DIR}/stripped"
OUTPUT_NONSTRIPPED="${OUTPUT_DIR}/nonstripped"

cd "${WORK_DIR}"

if [ ! -f "configure" ]; then
    echo ""
    echo "Configure script not found. Running bootstrap..."
    echo "------------------------------------------------"
    ./bootstrap
fi

if [ -d "${BUILD_DIR}" ]; then
    echo "Cleaning previous build directory..."
    rm -rf "${BUILD_DIR}"
fi

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo ""
echo "Configuring coreutils for ARMv4..."
echo "-----------------------------------"

export CC=mips-linux-gnu-gcc
export CXX=mips-linux-gnu-g++
export AR=mips-linux-gnu-ar
export AS=mips-linux-gnu-as
export LD=mips-linux-gnu-ld
export RANLIB=mips-linux-gnu-ranlib
export STRIP=mips-linux-gnu-strip
export CFLAGS="-O2"

../configure \
    --host=mips-linux-gnu \
    --build=x86_64-linux-gnu \

echo ""
echo "Building coreutils..."
echo "---------------------"

make -j"$(nproc)"

echo ""
echo "Installing non-stripped binaries to ${OUTPUT_NONSTRIPPED}..."
echo "-----------------------------------------------------------"
make install DESTDIR="${OUTPUT_NONSTRIPPED}"

echo ""
echo "Installing stripped binaries to ${OUTPUT_STRIPPED}..."
echo "--------------------------------------------------"
make install DESTDIR="${OUTPUT_STRIPPED}"
find "${OUTPUT_STRIPPED}/usr/local/bin" -type f -exec "${STRIP}" {} \;

echo ""
echo "Cleaning build directory..."
echo "--------------------------"
rm -rf "${BUILD_DIR}"

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo "Nonstripped binaries: ${OUTPUT_NONSTRIPPED}/usr/local/bin"
echo "Stripped binaries:    ${OUTPUT_STRIPPED}/usr/local/bin"

echo ""
echo "To verify:"
echo "  file ${OUTPUT_NONSTRIPPED}/usr/local/bin/ls"
echo "  file ${OUTPUT_STRIPPED}/usr/local/bin/ls"
echo "  arm-linux-gnueabihf-readelf -h ${OUTPUT_STRIPPED}/usr/local/bin/ls | grep Flags"
