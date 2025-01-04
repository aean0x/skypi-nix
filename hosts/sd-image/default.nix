# SD card image configuration for ROCK5 ITX
{ config, lib, pkgs, settings, ... }:

{
  imports = [
    ./cross-compile.nix
    ./install-scripts.nix
    ../common/kernel.nix
  ];

  # Use extlinux boot configuration
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

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
    imageBaseName = "${settings.hostName}-${settings.kernelVersion}-sdcard.img";
    compressImage = false;
    firmwareSize = 64;  # Increased for RK3588 bootloader
    firmwarePartitionName = "firmware";
    populateFirmwareCommands = ''
      # Copy vendor bootloader image
      cp ${./bootloader.img} firmware/bootloader.img
      # Write it to the start of the firmware partition
      dd if=firmware/bootloader.img of=$img bs=512 conv=notrunc
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
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
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
    settings.UsePAM = true;
    settings.PermitEmptyPasswords = true;
  };

  # Minimal system packages
  environment.systemPackages = lib.mkForce (with pkgs; [
    iproute2
    openssh
    mtdutils  # For flash operations
    coreutils # For cmp and other utilities
  ]);

  # Disable unnecessary services
  services.xserver.enable = lib.mkForce false;
  documentation.enable = false;
  programs.command-not-found.enable = false;

  system.stateVersion = "25.05";
} 