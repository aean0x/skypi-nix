{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix"
  ];

  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
        -c ${config.system.build.toplevel} \
        -d ./files/boot
    '';
    compressImage = false;
    imageBaseName = "nixos-rock5-itx";
  };

  # Dual-mode filesystem configuration for both SD card and eMMC
  fileSystems = {
    "/" = lib.mkForce {
      device =
        if config.sdImage.enable or false
        then "/dev/disk/by-label/NIXOS_SD"
        else "/dev/mmcblk0p3";
      fsType = "ext4";
    };

    "/boot/efi" = lib.mkForce {
      device =
        if config.sdImage.enable or false
        then "/dev/disk/by-label/ESP"
        else "/dev/mmcblk0p2";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };
} 