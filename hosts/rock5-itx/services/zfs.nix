{
  lib,
  config,
  pkgs,
  ...
}: {
  # Kernel configuration for ZFS support
  boot = {
    # Add ZFS kernel module patches
    kernelPatches = lib.mkOrder 1500 [{
      name = "zfs-kernel-config";
      patch = null;
      extraStructuredConfig = with lib.kernel; {
        ZFS = module;
        ZLIB_DEFLATE = yes;
        ZLIB_INFLATE = yes;
        CRYPTO_SHA256 = yes;
        CRYPTO_SHA512 = yes;
        CRYPTO_AES = yes;
      };
    }];

    # Load ZFS kernel modules
    kernelModules = [ "zfs" ];
    initrd.availableKernelModules = [ "zfs" ];
  };

  # Add ZFS to supported filesystems
  boot.supportedFilesystems = [ "zfs" ];

  # ZFS service configuration
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
    trim.enable = true;
  };

  environment.systemPackages = with pkgs; [
    zfs
    zfs-prune-snapshots
  ];
}
