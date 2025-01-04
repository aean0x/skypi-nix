# Partition layout for RK3588 SD card image
{ config, lib, ... }:

{
  sdImage = {
    # Use GPT partition table
    format = "gpt";
    firstLba = 64;  # Start at sector 64 (32KB)

    partitions = {
      idbloader = {
        start = 64;  # 32KB
        size = 16320;  # 8MB - 32KB
        source = ../../firmware/output/idbloader.img;
        type = "8DA63339-0007-60C0-C436-083AC8230908";  # U-Boot SPL
      };

      uboot = {
        start = 16384;  # 8MB
        size = 32768;  # 16MB
        source = ../../firmware/output/u-boot.itb;
        type = "8DA63339-0007-60C0-C436-083AC8230908";  # U-Boot
      };

      trust = {
        start = 49152;  # 24MB
        size = 16384;  # 8MB
        source = ../../firmware/output/trust.img;
        type = "8DA63339-0007-60C0-C436-083AC8230908";  # ARM Trusted Firmware
      };

      boot = {
        start = 65536;  # 32MB
        size = 131072;  # 64MB
        type = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";  # EFI System Partition
        attrs = "LegacyBIOSBootable";
      };

      root = {
        start = 196608;  # 96MB
        type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";  # Linux filesystem
      };
    };
  };
} 