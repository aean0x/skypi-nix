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
    
    pkgsForSystem = system: import nixpkgs {
      inherit system;
      config.allowBroken = true;
    };

    pkgsForCross = import nixpkgs {
      system = hostSystem;
      crossSystem = {
        config = "aarch64-unknown-linux-gnu";
        system = targetSystem;
      };
      config.allowBroken = true;
    };
  in
  {
    devShells.${hostSystem}.default = 
      let pkgs = pkgsForSystem hostSystem;
      in import ./shell.nix { inherit pkgs; };

    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      pkgs = pkgsForCross;
      modules = [
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

    packages.${hostSystem} = {
      sdImage = self.nixosConfigurations.${secrets.hostName}.config.system.build.sdImage;
      default = self.packages.${hostSystem}.sdImage;
    };
  };
}