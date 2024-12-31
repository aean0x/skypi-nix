{
  config,
  pkgs,
  ...
}: {
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    podman-tui
  ];

  # Enable cgroups v2
  boot.kernelParams = ["systemd.unified_cgroup_hierarchy=1"];

  # Create default podman network with DNS
  systemd.services.podman-network-default = {
    description = "Create default podman network";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman network exists podman || \
      ${pkgs.podman}/bin/podman network create podman
    '';
  };
}
