# Cross-compilation configuration for SD card image
{ lib, pkgs, ... }:
let
  crossGlibcDev = "${pkgs.glibc.dev}";
  crossGccInc = "${pkgs.gcc}/lib/gcc/${pkgs.stdenv.targetPlatform.config}/${pkgs.gcc.version}/include";
in {
  config = {
    nixpkgs.overlays = [
      (self: super: {
        unbound = super.unbound.overrideAttrs (oldAttrs: {
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
            pkgs.buildPackages.bison
            pkgs.buildPackages.flex
            pkgs.buildPackages.perl
          ];
          YACC = "${pkgs.buildPackages.bison}/bin/yacc";
        });
      })
    ];
  };
} 