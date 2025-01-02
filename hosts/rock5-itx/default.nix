# Main system configuration for ROCK5 ITX
{ config, pkgs, lib, ... }:

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
  networking.hostName = config.secrets.hostName;
  networking.useDHCP = true;

  # User configuration
  users.users.${config.secrets.adminUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = config.secrets.sshKeys;
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
} 