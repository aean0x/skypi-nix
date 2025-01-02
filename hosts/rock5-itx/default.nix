# Main system configuration for ROCK5 ITX
{ config, pkgs, lib, secrets, ... }:

{
  imports = [
    # Hardware and system configuration
    ./hardware.nix
    ./pools.nix
    
    # Services
    ./services/cockpit.nix
    ./services/containers.nix
    ./services/fan-control.nix
    ./services/podman.nix
    ./services/remote-desktop.nix
    ./services/zfs.nix
  ];

  # System configuration
  networking.hostName = secrets.hostName;
  networking.useDHCP = true;

  # User configuration
  users.users.${secrets.adminUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = secrets.sshKeys;
  };

  # Enable SSH access
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    wget
    curl
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
} 