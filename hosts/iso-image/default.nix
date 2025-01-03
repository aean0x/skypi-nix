# Minimal SD card image configuration
{ config, lib, pkgs, secrets, ... }:

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

  # SSH access
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # ISO image configuration
  isoImage = {
    isoName = lib.mkForce "nixos-rock5-itx.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    appendToMenuLabel = " Rock5 ITX Installer";
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
