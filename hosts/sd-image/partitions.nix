# Partition layout for RK3588 SD card image
{ config, lib, ... }:

let
  partitionOptions = lib.types.submodule ({ config, ... }: {
    options = {
      name = lib.mkOption {
        default = config._module.args.name;
        type = lib.types.nullOr lib.types.str;
        description = "Name of the partition";
      };

      start = lib.mkOption {
        default = null;
        type = lib.types.int;
        description = "Start of the partition in sectors (512 byte)";
      };

      size = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.int;
        description = "Size of the partition in sectors (512 byte)";
      };

      source = lib.mkOption {
        default = null;
        type = lib.types.path;
        description = "Source file that will be copied to partition";
      };

      attrs = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
        description = "Additional partition attributes";
      };

      type = lib.mkOption {
        default = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
        type = lib.types.str;
        description = "Partition type GUID (defaults to Linux filesystem)";
      };

      useBootPartition = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = "Whether this partition should be used as boot partition";
      };
    };
  });

  cfg = config.sdImage;
in {
  options.sdImage = {
    format = lib.mkOption {
      default = "gpt";
      type = lib.types.enum [ "gpt" "mbr" ];
      description = "Partition table format";
    };

    firstLba = lib.mkOption {
      default = 64;
      type = lib.types.int;
      description = "First logical block address";
    };

    partitions = lib.mkOption {
      default = {};
      type = lib.types.attrsOf partitionOptions;
      description = "Partitions to create in the image";
    };
  };

  config = {
    sdImage = {
      format = lib.mkDefault "gpt";
      firstLba = lib.mkDefault 64;
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
          useBootPartition = true;
        };

        root = {
          start = 196608;  # 96MB
          size = 4194304;  # 2GB
          type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";  # Linux filesystem
        };
      };
    };
  };
} 