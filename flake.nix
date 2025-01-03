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
  in
  {
    # Full system configuration (for running on target)
    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = nativePkgs;
      specialArgs = { inherit secrets; };
      modules = [
        ./hosts/common
        ./hosts/rock5-itx
      ];
    };

    # Minimal ISO image (bootstrap configuration)
    nixosConfigurations."${secrets.hostName}-isoimage" = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = crossPkgs;
      specialArgs = { inherit secrets; };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./hosts/common
        ./hosts/iso-image
      ];
    };

    # Build products
    packages.${hostSystem} = {
      isoImage = self.nixosConfigurations."${secrets.hostName}-isoimage".config.system.build.isoImage;
      default = self.packages.${hostSystem}.isoImage;
    };
  };
}