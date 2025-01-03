# Example secrets file - copy this to secrets.nix and replace with your values
{
  # Basic system configuration
  hostName = "SkyPi";  # Your desired hostname
  adminUser = "admin";  # Your desired username
  description = "ROCK5 NAS Server";

  # Replace with output of:
  # mkpasswd -m sha-512 your_password
  hashedPassword = "$6$example_hash$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

  # Replace with your SSH public key(s)
  # Generate with: ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...example...key rock5-server-access"
  ];

  # Service-specific credentials
  credentials = {
    nextcloud = {
      adminpass = "change_this_password";  # Nextcloud admin password
    };
  };
} 