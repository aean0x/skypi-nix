{
  # System
  hostName = "SkyPi";
  adminUser = "aean";
  setupPassword = "nixos"; # For SSH into the setup image
  description = "ROCK5 NAS Server";
  hostId = "8425e349";  # Required for ZFS, generated with `head -c 8 /etc/machine-id`

  # Build systems
  hostSystem = "x86_64-linux";    # System building the ISO
  targetSystem = "aarch64-linux"; # System that will run the OS

  # Kernel
  kernelVersion = "6.13-rc5";
  modDirVersion = "6.13.0-rc5";

  # URLs
  edk2FirmwareUrl = "https://github.com/edk2-porting/edk2-rk3588/releases/download/v0.12.1/rock-5-itx_UEFI_Release_v0.12.1.img";
  repoUrl = "https://github.com/aean0x/skypi-nix.git";

  # Replace with your SSH public key(s)
  # Generate with: ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub && cat ~/.ssh/id_ed25519.pub
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbxwWbFkWQb+BozyJkDXbfIdnKXoCAwJkTQMncdyG5r aean@nix-pc"
  ];

  # SOPS configuration
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      "user.password" = {};
      "services.nextcloud.adminpass" = {};
    };
  };
} 