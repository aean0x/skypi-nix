# SD card image configuration for ROCK5 ITX
{ config, lib, pkgs, settings, ... }:

{
  imports = [
    ./cross-compile.nix
    ./install-scripts.nix
    ../common/kernel.nix
  ];

  # Console configuration
  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelParams = [
    "console=ttyFIQ0,115200n8"
    "console=ttyS2,115200n8"
    "earlycon=uart8250,mmio32,0xfeb50000"
    "earlyprintk"
  ];

  # SD card image configuration
  sdImage = {
    imageBaseName = "${settings.hostName}-${settings.kernelVersion}";
    compressImage = false;
    firmwareSize = 64;  # Increased for RK3588 bootloader
    firmwarePartitionName = "firmware";
    firmwarePartitionOffset = 32;  # Start at 32MB to leave room for all bootloader components
    populateFirmwareCommands = '''';  # We'll write bootloader in postBuildCommands
    populateRootCommands = ''
      mkdir -p ./files/boot
    '';
    # Write bootloader components at their respective offsets
    postBuildCommands = ''
      # Write idbloader.img (IPL + SPL) at 32KB
      dd if=${../firmware/output/idbloader.img} of=$img bs=512 seek=64 conv=notrunc

      # Write u-boot.itb (U-Boot + DTB) at 8MB
      dd if=${../firmware/output/u-boot.itb} of=$img bs=512 seek=16384 conv=notrunc

      # Write trust.img (ATF + OP-TEE) at 24MB
      dd if=${../firmware/output/trust.img} of=$img bs=512 seek=49152 conv=notrunc
    '';
  };

  # Basic networking
  networking = {
    useDHCP = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  # Default user configuration
  users.users.${settings.adminUser} = {
    isNormalUser = true;
    password = settings.setupPassword;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      ChallengeResponseAuthentication = false;
      UsePAM = true;
    };
  };

  # Minimal system packages
  environment.systemPackages = lib.mkForce (with pkgs; [
    iproute2
    openssh
    mtdutils
    coreutils
  ]);

  # Disable unnecessary services
  services.xserver.enable = lib.mkForce false;
  documentation.enable = false;
  programs.command-not-found.enable = false;

  system.stateVersion = "25.05";
} 