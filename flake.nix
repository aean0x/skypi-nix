{
  description = "SkyPi NixOS configuration for ROCK 5 ITX";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ... } @ inputs: let
    inherit (self) outputs;
    settings = import ./settings.nix;
    system = settings.targetSystem;

    overlays = [
      (final: prev: {
        stable = import nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      })
    ];
  in {
    nixosConfigurations.SkyPi = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs settings; };
      modules = [
        { nixpkgs.overlays = overlays; }
        ./hosts/common/kernel.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users."${settings.adminUser}" = {
            imports = [
              ./home/home.nix
            ];
          };
        }
      ];
    };

    nixosConfigurations.SkyPi-ISO = nixpkgs.lib.nixosSystem {
      system = settings.targetSystem;
      specialArgs = { inherit inputs settings; };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./hosts/iso/default.nix
        ./hosts/iso/cross-compile.nix
      ];
    };

    packages.${settings.hostSystem}.iso = self.nixosConfigurations.SkyPi-ISO.config.system.build.isoImage;
  };
}