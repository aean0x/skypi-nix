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
    settings = import ./settings.nix;

    # Common nixpkgs configuration
    nixpkgsConfig = {
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };

    # For cross-compilation (ISO image building)
    crossPkgs = import nixpkgs ({
      system = settings.hostSystem;
      crossSystem = {
        config = "aarch64-unknown-linux-gnu";
        system = settings.targetSystem;
      };
    } // nixpkgsConfig);

    # For native builds on the target
    nativePkgs = import nixpkgs ({
      system = settings.targetSystem;
    } // nixpkgsConfig);
  in
  {
    # Full system configuration (for running on target)
    nixosConfigurations.${settings.hostName} = nixpkgs.lib.nixosSystem {
      system = settings.targetSystem;
      pkgs = nativePkgs;
      specialArgs = { inherit settings; };
      modules = [
        sops-nix.nixosModules.sops
        ./hosts/common
        ./hosts/rock5-itx
      ];
    };

    # Minimal ISO image (bootstrap configuration)
    nixosConfigurations."${settings.hostName}-isoimage" = nixpkgs.lib.nixosSystem {
      system = settings.targetSystem;
      pkgs = crossPkgs;
      specialArgs = { inherit settings; };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        sops-nix.nixosModules.sops
        ./hosts/common
        ./hosts/iso-image
      ];
    };

    # Build products
    packages.${settings.hostSystem} = {
      isoImage = self.nixosConfigurations."${settings.hostName}-isoimage".config.system.build.isoImage;
      default = self.packages.${settings.hostSystem}.isoImage;
    };
  };
}