# Installation scripts for initial setup
{ config, pkgs, lib, settings, ... }:

let
  fs = lib.fileset;
  edk2FirmwareUrl = settings.edk2FirmwareUrl;
  repoUrl = settings.repoUrl;
in
{
  environment.systemPackages = with pkgs; [
    # Individual setup scripts
    (pkgs.writeScriptBin "prepare-emmc" ''
      #!/bin/sh
      set -e
      echo "Preparing eMMC device..."
      dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=64
      sync
      
      parted /dev/mmcblk0 -- mklabel gpt
      parted /dev/mmcblk0 -- mkpart ESP fat32 1MiB 512MiB
      parted /dev/mmcblk0 -- set 1 esp on
      parted /dev/mmcblk0 -- mkpart primary 512MiB 100%
      
      mkfs.vfat -F 32 -n ESP /dev/mmcblk0p1
      mkfs.ext4 -L nixos /dev/mmcblk0p2
      sync
      echo "eMMC preparation complete!"
    '')

    (pkgs.writeScriptBin "flash-edk2" ''
      #!/bin/sh
      set -e

      if [ ! -e /dev/mtdblock0 ]; then
        echo "Error: SPI flash device /dev/mtdblock0 not found!"
        exit 1
      fi

      # Create a 16MB zero-filled image for verification
      echo "Creating zero-filled verification image..."
      dd if=/dev/zero of=/tmp/zero.img bs=1M count=16
      sync

      echo "Erasing SPI-NOR flash (this may take up to 5 minutes)..."
      dd if=/tmp/zero.img of=/dev/mtdblock0
      sync
      
      echo "Verifying flash erase..."
      if ! cmp -s /tmp/zero.img /dev/mtdblock0; then
        echo "Error: Flash erase verification failed!"
        exit 1
      fi
      echo "Flash erase verified successfully."

      echo "Downloading EDK2 firmware..."
      curl -L -o /tmp/edk2.img "${edk2FirmwareUrl}"
      sync
      
      echo "Flashing EDK2 firmware..."
      dd if=/tmp/edk2.img of=/dev/mtdblock0
      sync

      echo "Verifying firmware flash..."
      if ! cmp -s /tmp/edk2.img /dev/mtdblock0; then
        echo "Error: Firmware flash verification failed!"
        exit 1
      fi
      
      echo "EDK2 firmware flashed and verified successfully!"
      rm -f /tmp/zero.img /tmp/edk2.img
    '')

    (pkgs.writeScriptBin "setup-repo" ''
      #!/bin/sh
      set -e
      mkdir -p ~/setup
      cd ~/setup
      git clone "${repoUrl}"
      chown -R $USER:users ~/setup
    '')

    # Main orchestrator script
    (pkgs.writeScriptBin "install-skypi" ''
      #!/bin/sh
      set -e
      
      echo "SkyPi NixOS Installation Script"
      echo "==============================="
      echo
      
      read -p "Prepare eMMC storage? This will ERASE ALL DATA! (y/N) " answer
      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        prepare-emmc
      fi
      
      read -p "Flash EDK2 UEFI firmware? (y/N) " answer
      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        flash-edk2
      fi
      
      read -p "Clone configuration repository? (y/N) " answer
      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        setup-repo
      fi
      
      echo
      echo "Installation steps completed!"
      echo "IMPORTANT: Before building the system, ensure your SOPS key is in /var/lib/sops-nix/key.txt"
      echo "If you haven't done so, configure secrets in the repo."
      echo
      echo "To build and switch to the new configuration, run:"
      echo "cd ~/setup/skypi-nix && sudo nixos-rebuild switch --flake .#"
    '')

    # Required tools
    git
    parted
    curl
    mtdutils
    age
    sops
  ];
} 