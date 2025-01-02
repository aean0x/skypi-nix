{ pkgs ? import <nixpkgs> { } }:

let
  crossPkgs = import pkgs.path {
    system = "x86_64-linux";
    crossSystem = {
      config = "aarch64-unknown-linux-gnu";
      system = "aarch64-linux";
    };
    config.allowBroken = true;
  };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    ncurses
    gcc
    gnumake
    bc
    openssl
    flex
    bison
    elfutils
    util-linux
    coreutils
    crossPkgs.zfs
  ];

  buildInputs = with pkgs; [
    nixos-rebuild
  ];

  shellHook = ''
    export KERNEL_CROSS_BUILD=1
  '';
}
