# Minimal SD card image configuration
{ config, lib, pkgs, settings, ... }:

{
  imports = [
    ./cross-compile.nix
    ./install-scripts.nix
    ../common/kernel.nix
  ];

  # Boot configuration for UEFI
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
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

  # ISO image configuration
  isoImage = {
    isoName = lib.mkForce "${settings.hostName}-${settings.kernelVersion}-nixos.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    appendToMenuLabel = "${settings.hostName} Nix Installer";
  };

  # Minimal system packages
  environment.systemPackages = lib.mkForce (with pkgs; [
    iproute2
    openssh
  ]);

  # Disable installation media default packages
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];

  # Disable unnecessary services
  services.xserver.enable = lib.mkForce false;
  documentation.enable = false;
  programs.command-not-found.enable = false;

  system.stateVersion = "25.05";
} 
