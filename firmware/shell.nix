{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gcc
    binutils
    gnumake
    python3
    bison
    flex
    dtc
    bc
    which
    pkg-config
    openssl
    ncurses
    pkgsCross.aarch64-multiplatform.buildPackages.gcc
    python3Packages.setuptools
    swig
  ];

  shellHook = ''
    echo "U-Boot build environment ready!"
    echo "Run ./build-bootloader.sh to build the bootloader"
  '';
} 