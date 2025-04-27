# Partition layout for RK3588 SD card image
{ config, lib, ... }:

{
  sdImage = {
    # Write bootloader images before partitions
    populateFirmwareCommands = ''
      # Write idbloader.img at sector 64 (32KB)
      dd if=${../../firmware/output/idbloader.img} of=$img seek=64 conv=notrunc
      sync
      echo "Verifying idbloader.img..."
      IDBLOADER_WRITTEN=$(dd if=$img skip=64 bs=512 iflag=count_bytes count=315392 | sha256sum)
      IDBLOADER_ORIG=$(dd if=${../../firmware/output/idbloader.img} iflag=count_bytes count=315392 | sha256sum)
      if [ "$IDBLOADER_WRITTEN" != "$IDBLOADER_ORIG" ]; then
        echo "Error: idbloader.img verification failed"
        exit 1
      fi
      
      # Write u-boot.itb at sector 16384 (8MB)
      dd if=${../../firmware/output/u-boot.itb} of=$img seek=16384 conv=notrunc
      sync
      echo "Verifying u-boot.itb..."
      UBOOT_WRITTEN=$(dd if=$img skip=16384 bs=512 iflag=count_bytes count=1501696 | sha256sum)
      UBOOT_ORIG=$(dd if=${../../firmware/output/u-boot.itb} iflag=count_bytes count=1501696 | sha256sum)
      if [ "$UBOOT_WRITTEN" != "$UBOOT_ORIG" ]; then
        echo "Error: u-boot.itb verification failed"
        exit 1
      fi
    '';

    # Start firmware partition after bootloader images (32MB)
    firmwarePartitionOffset = 32;  # 32MB
    firmwareSize = 64;            # 64MB
    firmwarePartitionName = "ESP";
    firmwarePartitionID = "C12A7328";  # EFI System Partition GUID

    # Don't compress the image
    compressImage = false;

    # Post-build commands to set partition attributes and verify image
    postBuildCommands = ''
      # Set partition type to EFI System Partition
      sfdisk --part-type $img 1 ef
      # Set bootable flag on root partition
      sfdisk --part-attrs $img 2 LegacyBIOSBootable

      # Ensure root partition is at least 2GB
      ROOT_START=$(sfdisk -d $img | grep "$img"2 | awk '{print $4}' | tr -d ,)
      ROOT_SIZE=$(( 4194304 - ROOT_START ))  # 2GB in sectors
      echo "Resizing root partition to $ROOT_SIZE sectors..."
      echo ",+," | sfdisk -N 2 $img

      echo "=== Image Information ==="
      fdisk -l $img
      echo "=== Partition Table ==="
      sfdisk -d $img
      echo "=== Bootloader Regions ==="
      echo "idbloader.img (32KB - 8MB):"
      dd if=$img skip=64 bs=512 count=1 2>/dev/null | hexdump -C | head -n 1
      echo "u-boot.itb (8MB - 24MB):"
      dd if=$img skip=16384 bs=512 count=1 2>/dev/null | hexdump -C | head -n 1

      # Extract and verify FAT filesystem
      echo "=== FAT Filesystem Information ==="
      dd if=$img skip=65536 bs=512 count=131072 of=firmware_part.img
      fsck.fat -v firmware_part.img
      rm -f firmware_part.img
    '';
  };
} 