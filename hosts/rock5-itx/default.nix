# Main system configuration for ROCK5 ITX
{ config, pkgs, lib, secrets, ... }:

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
    hostName = secrets.hostName;
    useDHCP = true;
    hostId = "8425e349";  # Required for ZFS, generated with `head -c 8 /etc/machine-id`
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

  system.stateVersion = "25.05";
} 