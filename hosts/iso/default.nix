{ pkgs, lib, config, ... }:

{
  imports = [
    ../common/kernel.nix
  ];

  system.stateVersion = "25.05";

  # ISO specific configuration
  isoImage = {
    isoName = "SkyPi-ROCK5-ITX-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = "SkyPi_ROCK5_ITX";
    makeEfiBootable = true;
    makeBiosBootable = false;
  };

  # Include install script and necessary tools in the ISO
  environment.systemPackages = with pkgs; [
    (callPackage ./install.nix { })
    parted
    git
    util-linux
    gptfdisk
    wget
    curl
    iw
  ];

  # Ensure networking is enabled
  networking.useDHCP = lib.mkForce true;

  # Basic desktop environment for setup
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Enable SSH for remote setup
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # Default user for ISO
  users.users.setup = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "nixos";
  };
} 