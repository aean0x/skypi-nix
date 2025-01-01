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
          ./configuration.nix
          ./modules/kernel.nix
          ./modules/partitions.nix
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

    checks.${system}.default = self.nixosConfigurations.${secrets.hostName}.config.system.build.toplevel;
  };
}