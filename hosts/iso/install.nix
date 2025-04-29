# Nix Installer Script Package

{ pkgs, lib, stdenv, fetchurl, settings, ... }:

stdenv.mkDerivation rec {
  pname = "nixinstall";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/nixinstall << EOF
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p parted git util-linux gptfdisk wget curl iw

# NixOS Installer

set -e

# Configuration variables directly injected
HOST_NAME="${settings.hostName}"
REPO_URL="${settings.repoUrl}"
DESCRIPTION="${settings.description}"

echo "Welcome to NixOS Installer for \$DESCRIPTION"

# Check if running as root
if [ "\$EUID" -ne 0 ]; then
  echo "This installer must be run as root. Please use sudo."
  exit 1
fi

# Detect target device
echo "Detecting storage devices..."
lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT

echo "Please enter the target device for installation (e.g., /dev/sda, /dev/mmcblk0, /dev/nvme0n1):"
read TARGET_DEVICE

# Validate target device
if [ ! -b "\$TARGET_DEVICE" ]; then
  echo "Error: \$TARGET_DEVICE is not a valid block device."
  exit 1
fi

# Confirm with user
echo "WARNING: All data on \$TARGET_DEVICE will be erased!"
echo "Do you want to continue? (y/N)"
read CONFIRM
if [ "\$CONFIRM" != "y" ] && [ "\$CONFIRM" != "Y" ]; then
  echo "Installation aborted."
  exit 1
fi

# Determine partition suffixes based on device name
if [[ "\$TARGET_DEVICE" =~ [0-9]\$ ]]; then
  PART1="''${TARGET_DEVICE}p1"
  PART2="''${TARGET_DEVICE}p2"
else
  PART1="''${TARGET_DEVICE}1"
  PART2="''${TARGET_DEVICE}2"
fi

# Partition the device
echo "Partitioning \$TARGET_DEVICE..."
wipefs -a "\$TARGET_DEVICE" || { echo "Failed to wipe filesystem signatures"; exit 1; }
parted -s "\$TARGET_DEVICE" mklabel gpt || { echo "Failed to create GPT label"; exit 1; }
parted -s "\$TARGET_DEVICE" mkpart primary fat32 1MiB 513MiB || { echo "Failed to create EFI partition"; exit 1; }
parted -s "\$TARGET_DEVICE" set 1 esp on || { echo "Failed to set ESP flag"; exit 1; }
parted -s "\$TARGET_DEVICE" set 1 boot on || { echo "Failed to set boot flag"; exit 1; }
parted -s "\$TARGET_DEVICE" mkpart primary ext4 513MiB 100% || { echo "Failed to create root partition"; exit 1; }

# Format partitions
echo "Formatting partitions..."
mkfs.vfat -n "EFI" "\$PART1" || { echo "Failed to format EFI partition"; exit 1; }
mkfs.ext4 -L "\$HOST_NAME-Root" "\$PART2" || { echo "Failed to format root partition"; exit 1; }

# Mount partitions
echo "Mounting partitions..."
mount "\$PART2" /mnt || { echo "Failed to mount root partition"; exit 1; }
mkdir -p /mnt/boot/efi
mount "\$PART1" /mnt/boot/efi || { echo "Failed to mount EFI partition"; exit 1; }

# Clone repository
echo "Cloning repository..."
git clone "\$REPO_URL" /tmp/nixos-config || { echo "Failed to clone repository"; exit 1; }

# Build system
echo "Building NixOS system..."
cd /tmp/nixos-config
nix build .#nixosConfigurations.\$HOST_NAME.config.system.build.toplevel || { echo "Failed to build NixOS system"; exit 1; }

# Install system
echo "Installing system..."
nixos-install --root /mnt --system ./result || { echo "Failed to install NixOS"; exit 1; }

# Unmount
echo "Unmounting..."
umount /mnt/boot/efi || { echo "Failed to unmount EFI partition"; exit 1; }
umount /mnt || { echo "Failed to unmount root partition"; exit 1; }

# Done
echo "Installation complete! Please remove the installation media and reboot."
EOF
    chmod +x $out/bin/nixinstall
  '';

  meta = with lib; {
    description = "NixOS installer script";
    platforms = platforms.linux;
  };
}