{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Base development tools
    gcc
    binutils
    gcc-arm-embedded
    gnumake
    git
    python3
    bc
    bzip2
    gnutar
    gzip
    wget
    which
    pkg-config
    openssl
    sudo
    
    # Docker support
    docker
    docker-compose
    
    # Additional tools
    ubootTools
    dtc
    ncurses
    pkgsCross.aarch64-multiplatform.buildPackages.gcc
    python3Packages.setuptools
    swig
    flex
    bison
  ];

  shellHook = ''
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
      echo "Warning: Docker daemon is not running"
    fi
  '';
} 