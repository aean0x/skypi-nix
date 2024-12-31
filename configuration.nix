{
  config,
  pkgs,
  ...
}: let
  secrets = let
    hasSecrets = builtins.pathExists ./secrets.nix;
    defaultSecrets = import ./secrets.example.nix;
  in
    if hasSecrets then import ./secrets.nix else defaultSecrets;
in {
  boot.kernelPackages = pkgs.linuxPackages_testing;

  networking = {
    networkmanager.enable = true;
    # Disable wireless to avoid conflict with NetworkManager
    wireless.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        9090 # Cockpit
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
