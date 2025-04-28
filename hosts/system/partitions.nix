# Storage configuration for ROCK5 ITX
{ config, lib, pkgs, ... }:

{
  # ZFS configuration
  boot = {
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "zfs" ];
    zfs.forceImportRoot = false;
  };

  services.zfs = {
    autoScrub.enable = true;
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

  # eMMC partition configuration
  fileSystems = {
    "/" = {
      device = "/dev/mmcblk0p2";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/mmcblk0p1";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };
} 