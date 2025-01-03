{
  description = "ROCK5 ITX NixOS Server Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
    fan-control = {
      url = "github:pymumu/fan-control-rock5b";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, sops-nix, fan-control, ... }:
  let
    hostSystem = "x86_64-linux";
    targetSystem = "aarch64-linux";

    # Common nixpkgs configuration
    nixpkgsConfig = {
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };

    # For cross-compilation (ISO image building)
    crossPkgs = import nixpkgs ({
      system = hostSystem;
      crossSystem = {
        config = "aarch64-unknown-linux-gnu";
        system = targetSystem;
      };
    } // nixpkgsConfig);

    # For native builds on the target
    nativePkgs = import nixpkgs ({
      system = targetSystem;
    } // nixpkgsConfig);

    # Helper to get hostname from a module evaluation
    getHostname = pkgs: let
      module = nixpkgs.lib.evalModules {
        modules = [
          sops-nix.nixosModules.sops
          ./sops.nix
        ];
      };
    in module.config.hostname;

    hostname = getHostname nativePkgs;
  in
  {
    # Full system configuration (for running on target)
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = nativePkgs;
      modules = [
        sops-nix.nixosModules.sops
        ./sops.nix
        ./hosts/common
        ./hosts/rock5-itx
      ];
    };

    # Minimal ISO image (bootstrap configuration)
    nixosConfigurations."${hostname}-isoimage" = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = crossPkgs;
      modules = [
        sops-nix.nixosModules.sops
        ./sops.nix
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./hosts/common
        ./hosts/iso-image
      ];
    };

    # Build products
    packages.${hostSystem} = {
      isoImage = self.nixosConfigurations."${hostname}-isoimage".config.system.build.isoImage;
      default = self.packages.${hostSystem}.isoImage;
    };
  };
}