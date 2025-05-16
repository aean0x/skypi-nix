{ pkgs, lib, config, settings, ... }:

{
  imports = [
    ../common/kernel.nix
  ];

  system.stateVersion = "25.05";

  # ISO specific configuration
  isoImage = {
    isoName = "${settings.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = "${settings.hostName}_${config.system.nixos.label}";
    makeEfiBootable = true;
    makeBiosBootable = false;
  };

  # Disable git and documentation to avoid build issues during ISO cross-compilation
  programs.git.enable = false;
  documentation.enable = false;
  documentation.man.enable = false;
  documentation.doc.enable = false;

  # Include install script and SOPS key
  environment.systemPackages = with pkgs; [
    (callPackage ./install.nix { inherit settings; })
    # Add the SOPS key to the ISO
    (pkgs.runCommand "sops-key" {} ''
      mkdir -p $out/var/lib/sops-nix
      cp ${pkgs.writeText "sops-key" (builtins.readFile ./../../secrets/key.txt)} $out/var/lib/sops-nix/key.txt
      chmod 600 $out/var/lib/sops-nix/key.txt
    '')
  ];

  # Ensure networking is enabled
  networking.useDHCP = lib.mkForce true;

  # Enable SSH for remote setup
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # Default user for ISO
  users.users.setup = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "nixos";
  };
} 