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
    hostSystem = "x86_64-linux";
    targetSystem = "aarch64-linux";

    # For cross-compilation (SD image building)
    crossPkgs = import nixpkgs {
      system = hostSystem;
      crossSystem = {
        config = "aarch64-unknown-linux-gnu";
        system = targetSystem;
      };
      config.allowBroken = true;
    };

    # For native builds on the target
    nativePkgs = import nixpkgs {
      system = targetSystem;
      config.allowBroken = true;
    };

    # Common modules configuration
    commonModules = {
      _module.args = {
        inherit fan-control;
      };
    };
  in
  {
    # System configurations
    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = nativePkgs;
      modules = [
        commonModules
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
    };

    # Cross-compiled SD image
    nixosConfigurations."${secrets.hostName}-sdimage" = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = crossPkgs;
      modules = [
        commonModules
        ./configuration.nix
        ./modules/cross-compile.nix
        ./modules/kernel.nix
        ./modules/partitions.nix
        ./modules/zfs.nix
        { sdImage.enable = true; }
      ];
    };

    # Build products
    packages.${hostSystem} = {
      sdImage = self.nixosConfigurations."${secrets.hostName}-sdimage".config.system.build.sdImage;
      default = self.packages.${hostSystem}.sdImage;
    };
  };
}