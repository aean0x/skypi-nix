{
  hostName = "rock5-itx";
  adminUser = "admin";
  description = "Administrator";
  hashedPassword = "REPLACE_WITH_HASHED_PASSWORD";
  sshKeys = [
    "REPLACE_WITH_YOUR_SSH_PUBLIC_KEY"
  ];
  credentials = {
    nextcloud = {
      adminpass = "REPLACE_WITH_NEXTCLOUD_ADMIN_PASSWORD";
    };
  };
}
