# Cross compilation configuration
{ lib, pkgs, ... }:
{
  options = { };

  config = {
    nixpkgs.overlays = [
      (final: prev: {
        kernelBuildPackages = with final.buildPackages; [
          bison
          flex
          gcc
          gnumake
          pkg-config
          ncurses
          bc
          openssl
          elfutils
          util-linux
          coreutils
          binutils
        ];
      })
    ];

    environment.systemPackages = with pkgs; [
      kernelBuildPackages
      zfs
    ];
  };
} 