{ pkgs ? import <nixpkgs> { }
, isCross ? false
}:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Common tools needed for both native and cross builds
    bison
    byacc
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
  ] ++ (if isCross then [
    # Cross-compilation specific tools
    pkgs.buildPackages.gcc
    pkgs.buildPackages.binutils
  ] else [
    # Native-only tools
    zfs
  ]);

  shellHook = ''
    ${if isCross then "export KERNEL_CROSS_BUILD=1" else ""}
    echo "Entering ${if isCross then "cross-compilation" else "native"} environment"
  '';
}
