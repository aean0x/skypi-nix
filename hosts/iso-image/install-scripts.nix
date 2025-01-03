# Installation scripts for initial setup
{ pkgs, ... }:

let
  edk2FirmwareUrl = "https://github.com/edk2-porting/edk2-rk3588/releases/download/v0.12.1/rock-5-itx_UEFI_Release_v0.12.1.img";
  repoUrl = "https://github.com/aean0x/skypi-nix.git";
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
      echo "To build and switch to the new configuration, edit secrets.nix and run:"
      echo "cd ~/setup/skypi-nix && sudo nixos-rebuild switch --flake .#"
    '')

    # Required tools
    git
    parted
    curl
    mtdutils
  ];
} 