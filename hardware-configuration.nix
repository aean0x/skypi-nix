{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    # This module sets up the sdImage (or eMMC image) build logic for aarch64.
    "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix"
  ];

  ###########################
  # Bootloader & initrd
  ###########################
  boot = {
    # Provide Rockchip-friendly UART consoles (helps debugging).
    kernelParams = [
      "console=ttyFIQ0,115200n8"
      "console=ttyS2,115200n8"
      "earlycon=uart8250,mmio32,0xfeb50000"
      "earlyprintk"
    ];

    initrd.availableKernelModules = [
      "usbhid"
      "md_mod"
      "raid0"
      "raid1"
      "raid10"
      "raid456"
      "ext2"
      "ext4"
      "sd_mod"
      "sr_mod"
      "mmc_block"
      "uhci_hcd"
      "ehci_hcd"
      "ehci_pci"
      "ohci_hcd"
      "ohci_pci"
      "xhci_hcd"
      "xhci_pci"
      "hid_generic"
      "uas"
      "usb_storage"
      "sdhci_arasan"
      "dwmmc_rockchip"
    ];
    kernelModules = [];
    extraModulePackages = [];
  };

  ###########################
  # Disk image build config
  ###########################
  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
        -c ${config.system.build.toplevel} \
        -d ./files/boot
    '';
    compressImage = false;
    imageBaseName = "nixos-rock5-itx-monolithic";
  };

  ###########################
  # File systems
  ###########################
  fileSystems."/" = {
    device = "/dev/mmcblk0p3";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/mmcblk0p2"; # 300 MB EFI partition
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  ###########################
  # Misc recommended settings
  ###########################
  powerManagement.cpuFreqGovernor = "performance";
  hardware.enableRedistributableFirmware = true;
  networking.useDHCP = lib.mkDefault true;
}
