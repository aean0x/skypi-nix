# Remote desktop configuration
{ config, lib, pkgs, settings, ... }:

{
  services.xrdp = {
    enable = true;
    defaultWindowManager = "xfce4-session";
    openFirewall = true;
  };

  services.xserver = {
    enable = true;
    desktopManager = {
      xfce.enable = true;
      xterm.enable = false;
    };
    displayManager = {
      defaultSession = "xfce";
      autoLogin = {
        enable = true;
        user = settings.adminUser;
      };
    };
  };
}
