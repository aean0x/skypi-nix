{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ./home/secrets.nix;
  mkVolumeService = name: {
    description = "Create ${name} volume";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman volume exists ${name} || \
      ${pkgs.podman}/bin/podman volume create ${name}
    '';
  };

  volumes = [
    "nextcloud-data"
    "homeassistant-config"
  ];
in {
  virtualisation.oci-containers.containers = {
    nextcloud = {
      image = "nextcloud:latest";
      autoStart = true;
      environment = {
        NEXTCLOUD_ADMIN_USER = "admin";
        NEXTCLOUD_ADMIN_PASSWORD = secrets.credentials.nextcloud.adminpass;
      };
      volumes = [
        "nextcloud-data:/var/www/html"
      ];
      extraOptions = [
        "--network=podman"
      ];
    };

    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      volumes = [
        "homeassistant-config:/config"
      ];
      extraOptions = [
        "--network=podman"
        "--privileged"
      ];
    };
  };

  systemd.services =
    lib.genAttrs
    (map (name: "create-${name}") volumes)
    (name: mkVolumeService (lib.removePrefix "create-" name));
}