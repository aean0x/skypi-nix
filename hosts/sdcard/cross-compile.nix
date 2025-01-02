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

    # Minimal environment variables for cross-compilation
    environment.variables = {
      NIX_CFLAGS_COMPILE = lib.optionalString (pkgs.stdenv.buildPlatform != pkgs.stdenv.hostPlatform) ''
        -I${crossGlibcDev}/include
        -I${crossGccInc}
      '';
    };
  };
} 