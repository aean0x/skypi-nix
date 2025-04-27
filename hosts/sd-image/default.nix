# SD card image configuration for ROCK5 ITX
{ config, lib, pkgs, settings, ... }:

{
  imports = [
    ./cross-compile.nix
    ./install-scripts.nix
    ./partitions.nix
    ../common/kernel.nix
  ];

  # Boot configuration for U-Boot
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.configurationLimit = 1;

  # Console configuration
  boot.consoleLogLevel = lib.mkDefault 8;
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyS2,115200n8"
    "console=ttyFIQ0,115200n8"
    "earlycon=uart8250,mmio32,0xfeb50000"
    "earlyprintk"
    "debug"
    "loglevel=8"
    "ignore_loglevel"
    "printk.devkmsg=on"
  ];

  # SD card image configuration
  sdImage = {
    imageBaseName = "${settings.hostName}-${settings.kernelVersion}";
    compressImage = false;
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
    utillinux  # for sfdisk
  ]);

  # Disable unnecessary services
  services.xserver.enable = lib.mkForce false;
  documentation.enable = false;
  programs.command-not-found.enable = false;

  system.stateVersion = "25.05";
} 