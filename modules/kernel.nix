{ lib, pkgs, config, ... }: let
  kernelVersion = "6.13-rc5";

  kernelSrc = pkgs.fetchurl {
    url    = "https://git.kernel.org/torvalds/t/linux-${kernelVersion}.tar.gz";
    sha256 = "0yhqw3ddpmxjv82f50385dcg86cripm0rsl68xfv5qxrs4m6i7i3";
  };

  defconfig = pkgs.writeText "defconfig" ''
    # Basic architecture / platform
    CONFIG_ARM64=y
    CONFIG_ARCH_ROCKCHIP=y
    CONFIG_ARCH_RK3588=y
    CONFIG_ARM64_VA_BITS_48=y

    # Core crypto optimizations on ARM64
    CONFIG_CRYPTO_SHA256_ARM64=y
    CONFIG_CRYPTO_AES_ARM64=y
    CONFIG_CRYPTO_GHASH_ARM64_CE=y

    # Rockchip core SoC drivers
    CONFIG_ROCKCHIP_IOMMU=y
    CONFIG_ROCKCHIP_MBOX=y
    CONFIG_ROCKCHIP_IODOMAIN=y
    CONFIG_ROCKCHIP_PM_DOMAINS=y
    CONFIG_ROCKCHIP_TIMER=y
    CONFIG_ROCKCHIP_EFUSE=y
    CONFIG_ROCKCHIP_OTP=y
    CONFIG_ARM_ROCKCHIP_DMC_DEVFREQ=y

    # Thermal
    CONFIG_CPU_THERMAL=y
    CONFIG_THERMAL=y
    CONFIG_ROCKCHIP_THERMAL=y

    # Clocks / pinctrl / GPIO
    CONFIG_COMMON_CLK_ROCKCHIP=y
    CONFIG_COMMON_CLK_RK3588=y
    CONFIG_PINCTRL_ROCKCHIP=y
    CONFIG_GPIO_ROCKCHIP=y

    # PHYs (USB, PCIe, DP, etc.)
    CONFIG_PHY_ROCKCHIP_INNO_USB2=y
    CONFIG_PHY_ROCKCHIP_PCIE=y
    CONFIG_PHY_ROCKCHIP_TYPEC=y
    CONFIG_PHY_ROCKCHIP_DP=y
    CONFIG_PHY_ROCKCHIP_INNO_HDMI=y
    CONFIG_PHY_ROCKCHIP_SAMSUNG_HDPTX=y
    CONFIG_PHY_ROCKCHIP_USBDP=y
    CONFIG_PHY_ROCKCHIP_EMMC=y

    # MMC / SD
    CONFIG_MMC_DW_ROCKCHIP=y
    CONFIG_MMC_SDHCI_OF_DWCMSHC=y

    # SPI
    CONFIG_SPI_ROCKCHIP=y
    CONFIG_SPI_ROCKCHIP_SFC=y

    # PWM
    CONFIG_PWM_ROCKCHIP=y

    # I2C
    CONFIG_I2C_RK3X=y

    # Basic DRM / Display (if you need video output)
    CONFIG_DRM_ROCKCHIP=y
    CONFIG_ROCKCHIP_VOP2=y
    CONFIG_ROCKCHIP_DW_HDMI=y
    CONFIG_ROCKCHIP_DW_MIPI_DSI=y
    CONFIG_ROCKCHIP_ANALOGIX_DP=y
    CONFIG_ROCKCHIP_CDN_DP=y
    CONFIG_ROCKCHIP_INNO_HDMI=y
    CONFIG_ROCKCHIP_LVDS=y
    CONFIG_ROCKCHIP_MINI_DSI=y
  '';

  kernelPackagesCustom = pkgs.linuxPackagesFor (
    pkgs.linux_testing.override {
      argsOverride = {
        src = kernelSrc;
        version = kernelVersion;
        modDirVersion = kernelVersion;
        configfile = defconfig;
      };
      kernelPatches = [
        # 1) Re-affirm basic platform flags (often no-op in mainline, but harmless)
        {
          name = "rk3588-platform-support";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            ARCH_ROCKCHIP = yes;
            ARCH_RK3588 = yes;
            ARM64_VA_BITS_48 = yes;
          };
        }

        # 2) Enable ZFS as a module + required crypto
        {
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
        }
      ];
    }
  );
in {
  # Hardware-specific settings
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.enableRedistributableFirmware = true;
  networking.useDHCP = lib.mkDefault true;

  boot = {
    kernelPackages = kernelPackagesCustom;

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
      "xhci_hcd" "xhci_pci" "hid_generic" "uas" "usb_storage"
      "sdhci_of_dwcmshc" "zfs"
    ];

    kernelModules = [ "zfs" ];
    extraModulePackages = [];
  };

  boot.supportedFilesystems = [ "ext4" "vfat" "zfs" ];
  boot.zfs.forceImportRoot = false;

  environment.systemPackages = with pkgs; [
    linuxHeaders
    gnumake
    gcc
    pkg-config
    ncurses
    zfs
  ];
}
