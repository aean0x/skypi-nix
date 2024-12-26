{
  lib,
  pkgs,
  ...
}: {
  boot = {
    kernelModules = [
      "usbhid"
      "md_mod"
      "raid0"
      "raid1"
      "raid10"
      "raid456"
      "uas"
      "usb_storage"
    ];

    initrd.availableKernelModules = lib.mkAfter [
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
      "usbhid"
      "hid_generic"
      "uas"
      "usb_storage"
      "zfs"
    ];
  };
} 