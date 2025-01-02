# Installation scripts for initial setup
{ pkgs, secrets, ... }:

{
  environment.systemPackages = with pkgs; [
    # Script packages
    (pkgs.writeScriptBin "setup-scripts" ''
      mkdir -p /root/setup-scripts
      
      cat > /root/setup-scripts/prepare-emmc.sh << 'EOF'
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
      EOF
      
      cat > /root/setup-scripts/flash-edk2.sh << 'EOF'
      #!/bin/sh
      set -e
      FIRMWARE_URL="https://github.com/edk2-porting/edk2-rk3588/releases/download/v0.12.1/rock-5-itx_UEFI_Release_v0.12.1.img"
      echo "Downloading latest EDK2 firmware..."
      curl -L -o /tmp/edk2.img "$FIRMWARE_URL"
      
      echo "Erasing SPI-NOR flash..."
      dd if=/dev/zero of=/dev/mtd0 bs=1M count=16
      sync
      
      echo "Flashing EDK2 firmware..."
      dd if=/tmp/edk2.img of=/dev/mtd0
      sync
      echo "EDK2 firmware flashed successfully!"
      EOF
      
      chmod +x /root/setup-scripts/*.sh
    '')

    (pkgs.writeScriptBin "setup-repo" ''
      mkdir -p /home/${secrets.adminUser}/setup
      cd /home/${secrets.adminUser}/setup
      git clone https://github.com/aean0x/skypi-nix.git
      chown -R ${secrets.adminUser}:users /home/${secrets.adminUser}/setup
    '')

    # Required tools for the scripts
    git
    parted
    curl
    mtdutils
  ];
} 