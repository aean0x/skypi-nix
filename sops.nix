# SOPS configuration and secret access
{ config, lib, pkgs, ... }:

let
  # Helper function to get a secret value
  getSecret = path: config.sops.secrets."${path}".path;

  # Function to read a secret at evaluation time
  readSecretAtRuntime = path: lib.removeSuffix "\n" (builtins.readFile (getSecret path));
in {
  imports = [ ];

  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Define all secrets from the YAML file
    secrets = {
      "hostName" = { };
      "adminUser" = { };
      "description" = { };
      "hashedPassword" = { };
      "sshKeys" = { };
      "credentials/nextcloud/adminpass" = { };
    };
  };

  # Export a secrets attribute set that matches our previous secrets.nix structure
  options.secrets = lib.mkOption {
    type = lib.types.attrs;
    default = {
      hostName = readSecretAtRuntime "hostName";
      adminUser = readSecretAtRuntime "adminUser";
      description = readSecretAtRuntime "description";
      hashedPassword = readSecretAtRuntime "hashedPassword";
      sshKeys = [ (readSecretAtRuntime "sshKeys") ];
      credentials.nextcloud.adminpass = readSecretAtRuntime "credentials/nextcloud/adminpass";
    };
  };

  # Export the hostname for use in the flake
  options.hostname = lib.mkOption {
    type = lib.types.str;
    default = readSecretAtRuntime "hostName";
    description = "System hostname from SOPS configuration";
  };
} 