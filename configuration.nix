{ config, pkgs, ... }: let
  secrets = import ./secrets.nix;
in {
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  networking = {
    networkmanager.enable = true;
    # Disable wireless to avoid conflict with NetworkManager
    wireless.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22    # SSH
        9090  # Cockpit
      ];
    };
  };

  time.timeZone = "UTC";

  users.users.${secrets.adminUser} = {
    description = secrets.description;
    isNormalUser = true;
    group = secrets.adminUser;
    hashedPassword = secrets.hashedPassword;
    openssh.authorizedKeys.keys = secrets.sshKeys;
  };

  users.groups.${secrets.adminUser} = {};

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  security.polkit.enable = true;
  system.stateVersion = "24.11";
} 