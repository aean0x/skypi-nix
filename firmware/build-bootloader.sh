#!/usr/bin/env bash
set -euo pipefail

# Create output directory if it doesn't exist
mkdir -p output

# Ensure we're in the script's directory
cd "$(dirname "$0")"

# Create a downloads directory
mkdir -p downloads

# Download the latest miniloader if not present
if [ ! -f "downloads/rk3588_spl_loader_v1.15.113.bin" ]; then
    wget -P downloads https://dl.radxa.com/rock5/sw/images/loader/rk3588_spl_loader_v1.15.113.bin
fi

# Clone repositories if they don't exist
if [ ! -d "bsp" ]; then
    git clone https://github.com/radxa-repo/bsp.git
fi

cd bsp

# Add the directory as safe for git
git config --global --add safe.directory "$PWD"

# Initialize and update submodules
git submodule init
git submodule update

# Create custom defconfig patch
mkdir -p u-boot/rknext/0001-common
cat > u-boot/rknext/0001-common/0001-rock-5-itx-serial.patch << 'EOF'
From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001
From: SkyPi Builder <builder@skypi.local>
Date: Sat, 6 Jan 2024 12:00:00 +0000
Subject: [PATCH] rock-5-itx: configure serial and defaults

Set serial console baud rate to 115200 and configure basic settings.

Signed-off-by: SkyPi Builder <builder@skypi.local>
---
diff --git a/configs/rock-5-itx-rk3588_defconfig b/configs/rock-5-itx-rk3588_defconfig
index xxxxxxx..yyyyyyy 100644
--- a/configs/rock-5-itx-rk3588_defconfig
+++ b/configs/rock-5-itx-rk3588_defconfig
@@ -200,0 +201,15 @@
+CONFIG_BOOTDELAY=2
+CONFIG_BOOTCOMMAND="run distro_bootcmd"
+CONFIG_SYS_CONSOLE_INFO_QUIET=n
+
+# Serial configuration
+CONFIG_BAUDRATE=115200
+CONFIG_SYS_NS16550_CLK=24000000
+CONFIG_SYS_NS16550_MEM32=y
+CONFIG_SYS_NS16550_PORT_MAPPED=n
+CONFIG_DEBUG_UART_BASE=0xfeb50000
+CONFIG_DEBUG_UART_CLOCK=24000000
+
+# Basic debug output
+CONFIG_DEBUG=y
+CONFIG_DISPLAY_BOARDINFO=y
--
2.34.1
EOF

# Copy miniloader to the expected location
mkdir -p rkbin/bin/rk35
cp ../downloads/rk3588_spl_loader_v1.15.113.bin rkbin/bin/rk35/rk3588_spl_loader_v1.15.113.bin

# Build U-Boot using Docker with explicit paths
docker run --rm --privileged \
    -v "$PWD:/workspace" \
    -w /workspace \
    -e RKMINILOADER="/workspace/rkbin/bin/rk35/rk3588_spl_loader_v1.15.113.bin" \
    ghcr.io/radxa-repo/bsp:main \
    ./bsp --native-build u-boot rknext rock-5-itx

# Move only the generic .deb file to output
mv u-boot-rknext_*_arm64.deb ../output/uboot-generic.deb

cd ../output

# Extract the generic .deb file
echo "Extracting uboot-generic.deb..."
mkdir -p temp
cd temp
ar x "../uboot-generic.deb"

# Extract the data archive
if [ -f "data.tar.xz" ]; then
    tar xf data.tar.xz
elif [ -f "data.tar.gz" ]; then
    tar xf data.tar.gz
elif [ -f "data.tar.zst" ]; then
    zstd -d data.tar.zst -o data.tar
    tar xf data.tar
    rm data.tar
fi

# Move and rename the important files
UBOOT_DIR="usr/lib/u-boot/rock-5-itx"
if [ -d "$UBOOT_DIR" ]; then
    # Move and rename files based on their purpose
    mv "$UBOOT_DIR/idbloader.img" ../idbloader.img
    mv "$UBOOT_DIR/u-boot.itb" ../u-boot.itb
    mv "$UBOOT_DIR/rkboot.bin" ../rkboot.bin
fi

# Clean up
cd ..
rm -rf temp

echo "Build complete! The following files are available in the output directory:"
echo "  - idbloader.img (Combined TPL and SPL loader, flashed at 32KB)"
echo "  - u-boot.itb (U-Boot proper with FIT image, flashed at 8MB)"
echo "  - rkboot.bin (Rockchip maskrom mode loader, used only for recovery/flashing)"
echo "  - uboot-generic.deb (Original package file)" 