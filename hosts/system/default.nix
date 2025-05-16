# Main system configuration for ROCK5 ITX
{ config, pkgs, lib, settings, ... }:

{
  imports = [
    # Hardware and system configuration
    ./partitions.nix
    
    # Services
    # ./services/cockpit.nix
    # ./services/containers.nix
    # ./services/podman.nix
    # ./services/remote-desktop.nix
  ];

  # System configuration
  networking = {
    hostName = settings.hostName;
    networkmanager.enable = true;
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

  # Basic desktop environment for setup
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };

  # User configuration
  users.users.${settings.adminUser} = {
    isNormalUser = true;
    hashedPassword = config.sops.secrets."user.hashedPassword".path;
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
    sops
  ];

  system.stateVersion = "25.05";
}