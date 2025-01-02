# Minimal SD card image configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    # Import cross-compilation settings
    ./cross-compile.nix
  ];

  # Boot configuration
  boot.loader = {
    grub.enable = false;
    systemd-boot.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Basic networking
  networking = {
    hostName = config.secrets.hostName;
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
  users.users.${config.secrets.adminUser} = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = config.secrets.sshKeys;
  };

  # SD image configuration
  sdImage = {
    imageBaseName = "nixos-rock5-itx";
    compressImage = false;
  };

  # Disable unnecessary services
  services.xserver.enable = lib.mkForce false;
  documentation.enable = false;
  programs.command-not-found.enable = false;
  xdg.enable = false;
  fonts.enable = false;
  environment.noXlibs = true;

  # Minimal system packages
  environment.systemPackages = lib.mkForce (with pkgs; [
    iproute2
    openssh
  ]);
} 