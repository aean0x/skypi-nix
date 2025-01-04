#!/usr/bin/env bash

# Exit on error and enable debug output
set -e
set -x

# Configure git to trust all directories in the workspace
git config --global --unset-all safe.directory || true
git config --global --add safe.directory '*'

# Get the script's directory
FIRMWARE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${FIRMWARE_DIR}"

# Clone Rockchip BSP repository if not already present
if [ ! -d "rkbin" ]; then
    git clone --depth=1 https://github.com/radxa/rkbin.git
fi

# Clone Rockchip U-Boot repository if not already present
if [ ! -d "u-boot" ]; then
    git clone https://github.com/radxa/u-boot.git
fi

# First build the firmware images
cd rkbin

# Build bootloader images
./tools/boot_merger RKBOOT/RK3588MINIALL.ini

# Verify the SPL loader was created
if [ ! -f "rk3588_spl_loader_v1.16.113.bin" ]; then
    echo "Error: SPL loader not found. Using latest available version..."
    LATEST_SPL=$(ls -1 rk3588_spl_loader_v*.bin | sort -V | tail -n1)
    if [ -z "$LATEST_SPL" ]; then
        echo "Error: No SPL loader found!"
        exit 1
    fi
    echo "Found SPL loader: $LATEST_SPL"
    cp "$LATEST_SPL" rk3588_spl_loader_v1.16.113.bin
fi

# Copy required files with latest versions
cp rk3588_spl_loader_v1.16.113.bin idbloader.img
cp bin/rk35/rk3588_bl31_v1.46.elf bl31.elf
cp bin/rk35/rk3588_bl32_v1.15.bin tee.bin
cp bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.16.bin ddr.bin

# Create trust image
if [ ! -f "RKTRUST/RK3588TRUST.ini" ]; then
    echo "Error: Trust configuration not found!"
    exit 1
fi

# Create trust image with correct paths
RKBIN_DIR=$(pwd)
sed -e "s|PATH=bin/rk35/rk3588_bl31_v1.46.elf|PATH=${RKBIN_DIR}/bl31.elf|" \
    -e "s|PATH=bin/rk35/rk3588_bl32_v1.15.bin|PATH=${RKBIN_DIR}/tee.bin|" \
    RKTRUST/RK3588TRUST.ini > RKTRUST/RKTRUST.ini
cd RKTRUST
../tools/trust_merger RKTRUST.ini
cd ..
./tools/loaderimage --pack --trustos tee.bin ./trust.img

# Verify the firmware files
if [ ! -f "idbloader.img" ] || [ ! -f "trust.img" ]; then
    echo "Error: Failed to generate firmware images!"
    exit 1
fi

# Now build U-Boot
cd ../u-boot

# Make sure we're on the right branch
git remote set-url origin https://github.com/radxa/u-boot.git
git fetch origin
git checkout next-dev-v2024.10 || git checkout -b next-dev-v2024.10 origin/next-dev-v2024.10

# Configure for ROCK 5B (closest to ITX)
make mrproper
make CROSS_COMPILE=aarch64-unknown-linux-gnu- HOSTCC=gcc CC=aarch64-unknown-linux-gnu-gcc NO_PYTHON=1 rock-5b-rk3588_defconfig

# Build U-Boot with warnings not treated as errors
make CROSS_COMPILE=aarch64-unknown-linux-gnu- HOSTCC=gcc CC=aarch64-unknown-linux-gnu-gcc NO_PYTHON=1 -j$(nproc)

# Copy U-Boot image to rkbin directory
cp u-boot-dtb.bin ../rkbin/u-boot.itb

cd ..

# Copy final images to firmware directory
mkdir -p output
cp rkbin/idbloader.img ./output/
cp rkbin/trust.img ./output/
cp rkbin/u-boot.itb ./output/

echo "Bootloader images built successfully:"
echo "- idbloader.img (for SD card offset 32KB)"
echo "- trust.img (for SD card offset 24MB)"
echo "- u-boot.itb (for SD card offset 8MB)"
echo "Files are located in: ${FIRMWARE_DIR}" 