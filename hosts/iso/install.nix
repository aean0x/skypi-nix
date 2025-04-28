# SkyPi Installer Script Package for ROCK 5 ITX

{ pkgs, lib, stdenv, fetchurl, ... }:

stdenv.mkDerivation rec {
  pname = "skypi-installer";
  version = "0.2.0";

  src = ./install.sh;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/skypi-install
    chmod +x $out/bin/skypi-install
  '';

  meta = with lib; {
    description = "SkyPi installer script for ROCK 5 ITX";
    license = licenses.mit;
    maintainers = [ maintainers.aean ];
    platforms = platforms.linux;
  };
} 