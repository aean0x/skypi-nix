# Hardware configuration for Rock 5B
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix"
  ];

  boot = {
    kernelParams = [
      "console=ttyFIQ0,115200n8"
      "console=ttyS2,115200n8"
      "earlycon=uart8250,mmio32,0xfeb50000"
      "earlyprintk"
    ];

    initrd.availableKernelModules = [
      "usbhid" "md_mod" "raid0" "raid1" "raid10" "raid456" 
      "ext2" "ext4" "sd_mod" "sr_mod" "mmc_block" 
      "uhci_hcd" "ehci_hcd" "ehci_pci" "ohci_hcd" "ohci_pci" 
      "xhci_hcd" "xhci_pci" "usbhid" "hid_generic"
      "uas" "usb_storage" "sdhci_arasan" "dwmmc_rockchip"
    ];

    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
    compressImage = false;
    imageBaseName = "nixos-rock5b";
  };

  powerManagement.cpuFreqGovernor = "performance";
  hardware.enableRedistributableFirmware = true;
} 