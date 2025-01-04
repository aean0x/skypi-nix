# Main system configuration for ROCK5 ITX
{ config, pkgs, lib, settings, ... }:

{
  imports = [
    # Hardware and system configuration
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
  networking = {
    hostName = settings.hostName;
    useDHCP = true;
    hostId = settings.hostId;
  };

  # Boot configuration
  boot.loader = {
    grub = {
      enable = true;
      devices = [ "/dev/mmcblk0" ];  # Install GRUB to eMMC
      efiSupport = true;
    };
    efi.canTouchEfiVariables = true;
  };

  # User configuration
  users.users.${settings.adminUser} = {
    isNormalUser = true;
    password = config.sops.secrets."user.password".path;
    description = settings.description;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = settings.sshKeys;
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

  system.stateVersion = "25.05";
} 