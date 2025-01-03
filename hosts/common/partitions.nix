{ config, lib, ... }: {
  fileSystems = {
    "/" = lib.mkForce {
      device = lib.mkDefault
        (if config.isoImage.enable or false
         then "/dev/disk/by-label/NIXOS_SD"
         else "/dev/mmcblk0p3");
      fsType = "ext4";
    };

    "/boot/efi" = lib.mkForce {
      device = lib.mkDefault
        (if config.isoImage.enable or false
         then "/dev/disk/by-label/ESP"
         else "/dev/mmcblk0p2");
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };
} 