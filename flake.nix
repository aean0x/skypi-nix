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

    # Minimal SD card image (bootstrap configuration)
    nixosConfigurations."${secrets.hostName}-sdimage" = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = crossPkgs;
      specialArgs = { inherit secrets; };
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
        ./hosts/common
        ./hosts/sdcard
      ];
    };

    # Build products
    packages.${hostSystem} = {
      sdImage = self.nixosConfigurations."${secrets.hostName}-sdimage".config.system.build.sdImage;
      default = self.packages.${hostSystem}.sdImage;
    };
  };
}