# Minimal SD card image configuration
{ config, lib, pkgs, secrets, ... }:

{
  imports = [
    ./cross-compile.nix
    ./install-scripts.nix
  ];

  # Boot configuration for UEFI
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
  };

  # Basic networking
  networking = {
    hostName = secrets.hostName;
    useDHCP = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  # SSH access
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # User setup
  users.users.${secrets.adminUser} = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = secrets.sshKeys;
  };

  # Override installation media packages to be minimal
  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    contents = lib.mkForce [];
  };

  environment.systemPackages = lib.mkForce (with pkgs; [
    iproute2
    openssh
  ]);

  # Disable installation media default packages
  services.getty.autologinUser = lib.mkForce null;
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];

  # Disable unnecessary services
  services.xserver.enable = lib.mkForce false;
  documentation.enable = false;
  programs.command-not-found.enable = false;

  system.stateVersion = "25.05";
} 
