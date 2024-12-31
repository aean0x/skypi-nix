{
  description = "ROCK5 ITX NixOS Server Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    fan-control = {
      url = "github:pymumu/fan-control-rock5b";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    fan-control,
    ...
  } @ inputs: let
    secrets = let
      hasSecrets = builtins.pathExists ./secrets.nix;
      defaultSecrets = import ./secrets.example.nix;
    in
      if hasSecrets
      then import ./secrets.nix
      else defaultSecrets;
    lib = nixpkgs.lib;
    system = "aarch64-linux";

    pkgs = import nixpkgs {
      inherit system;
    };

    commonModules = [
      ./configuration.nix
      # ./modules/zfs.nix
      ./modules/podman.nix
      ./modules/cockpit.nix
      ./modules/containers.nix
      ./modules/remote-desktop.nix
      ./modules/fan-control.nix
      ./modules/kernel-modules.nix
    ];

    baseConfiguration = {
      networking.hostName = secrets.hostName;

      security.sudo.wheelNeedsPassword = false;

      boot.loader = {
        grub.enable = false;
        systemd-boot.enable = false;
        generic-extlinux-compatible.enable = true;
      };

      system.stateVersion = "24.11";
    };
  in {
    nixosConfigurations.${secrets.hostName} = lib.nixosSystem {
      inherit system;
      modules =
        [
          baseConfiguration
          ./hardware-configuration.nix
        ]
        ++ commonModules;
      specialArgs = {
        inherit fan-control;
      };
    };

    # Add SD image as a package output
    packages.${system} = {
      sdImage = self.nixosConfigurations.${secrets.hostName}.config.system.build.sdImage;
      default = self.packages.${system}.sdImage;
    };

    # Simple check to verify the configuration
    checks.${system}.default = self.nixosConfigurations.${secrets.hostName}.config.system.build.toplevel;
  };
}
