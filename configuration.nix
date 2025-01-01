{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  secrets = import ./secrets.nix;
in {
  networking = {
    hostName = secrets.hostName;

    networkmanager.enable = true;
    wireless.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        9090 # Cockpit
      ];
    };
  };

  security = {
    sudo.wheelNeedsPassword = false;
    polkit.enable = true;
  };

  boot.loader = {
    grub.enable = false;
    systemd-boot.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  time.timeZone = "UTC";

  users = {
    users.${secrets.adminUser} = {
      description = secrets.description;
      isNormalUser = true;
      group = secrets.adminUser;
      hashedPassword = secrets.hashedPassword;
      openssh.authorizedKeys.keys = secrets.sshKeys;
    };

    groups.${secrets.adminUser} = {};
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "24.11";
}