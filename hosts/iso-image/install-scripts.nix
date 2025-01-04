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
      parted /dev/mmcblk0 -- mkpart primary 7100MiB 100%
      
      mkfs.vfat -F 32 -n ESP /dev/mmcblk0p1
      mkfs.ext4 -L nixos /dev/mmcblk0p2
      sync
      echo "eMMC preparation complete!"
    '')

    (pkgs.writeScriptBin "flash-edk2" ''
      #!/bin/sh
      set -e
      echo "Downloading latest EDK2 firmware..."
      curl -L -o /tmp/edk2.img "${edk2FirmwareUrl}"
      
      echo "Erasing SPI-NOR flash..."
      dd if=/dev/zero of=/dev/mtdblock0 bs=1M count=16
      sync
      
      echo "Flashing EDK2 firmware..."
      dd if=/tmp/edk2.img of=/dev/mtdblock0
      sync
      echo "EDK2 firmware flashed successfully!"
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