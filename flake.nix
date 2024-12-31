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

  outputs = { self, nixpkgs, nixos-hardware, fan-control, ... }:
  let
    secrets = import ./secrets.nix;
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in
  {
    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      inherit system;
      modules =
        [
          ./hardware-configuration.nix
          ./configuration.nix
          ./modules/zfs.nix
          ./modules/podman.nix
          ./modules/cockpit.nix
          ./modules/containers.nix
          ./modules/remote-desktop.nix
          ./modules/fan-control.nix
        ];
      specialArgs = {};
    };

    packages.${system} = {
      sdImage = self.nixosConfigurations.${secrets.hostName}.config.system.build.sdImage;
      default = self.packages.${system}.sdImage;
    };

    boot.kernelPackages = pkgs.linuxPackages_testing.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [
        "/home/aean/skypi-nix/linux-6.13-rc4"
        "/usr/local/include"
      ];
    });

    checks.${system}.default = self.nixosConfigurations.${secrets.hostName}.config.system.build.toplevel;
  };
}