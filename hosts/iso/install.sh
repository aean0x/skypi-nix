#!/bin/bash

# SkyPi Installer for ROCK 5 ITX

set -e

echo "Welcome to SkyPi Installer for ROCK 5 ITX"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This installer must be run as root. Please use sudo."
  exit 1
fi

# Detect target device
echo "Detecting storage devices..."
lsblk

echo "Please enter the target device for installation (e.g., /dev/mmcblk0 or /dev/nvme0n1):"
read TARGET_DEVICE

if [ ! -e "$TARGET_DEVICE" ]; then
  echo "Error: Device $TARGET_DEVICE not found."
  exit 1
fi

# Confirm with user
echo "WARNING: All data on $TARGET_DEVICE will be erased!"
echo "Do you want to continue? (y/N)"
read CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Installation aborted."
  exit 1
fi

# Partition the device
echo "Partitioning $TARGET_DEVICE..."
# Clear existing partitions
wipefs -a "$TARGET_DEVICE"

# Create partitions
# EFI partition (512MB)
parted -s "$TARGET_DEVICE" mklabel gpt
parted -s "$TARGET_DEVICE" mkpart primary fat32 1MiB 513MiB
parted -s "$TARGET_DEVICE" set 1 esp on
parted -s "$TARGET_DEVICE" set 1 boot on

# Root partition (remaining space)
parted -s "$TARGET_DEVICE" mkpart primary ext4 513MiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.vfat -n "EFI" "${TARGET_DEVICE}p1"
mkfs.ext4 -L "SkyPi-Root" "${TARGET_DEVICE}p2"

# Mount partitions
echo "Mounting partitions..."
mount "${TARGET_DEVICE}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${TARGET_DEVICE}p1" /mnt/boot/efi

# Clone repository
echo "Cloning SkyPi repository..."
git clone https://github.com/aean0x/skypi-nix.git /tmp/skypi-nix

# Build system (assuming nix is available on ISO)
echo "Building NixOS system..."
cd /tmp/skypi-nix
nix build .#nixosConfigurations.SkyPi.config.system.build.toplevel

# Install system
echo "Installing system..."
nixos-install --root /mnt --system ./result

# Unmount
echo "Unmounting..."
umount /mnt/boot/efi
umount /mnt

# Done
echo "Installation complete! Please remove the installation media and reboot." 