{ config, pkgs, lib, ... }: let
  secrets = import ../secrets.nix;
  enableDesktop = config.services.xserver.enable or false;
in {
  options.services.remote-desktop = {
    enable = lib.mkEnableOption "Enable remote desktop support";
  };

  config = lib.mkIf config.services.remote-desktop.enable {
    # Basic X11 and XFCE setup
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xfce.enable = true;
          xfce.enableScreensaver = false;
        };
        displayManager.lightdm.enable = true;
      };

      displayManager.autoLogin = {
        enable = true;
        user = secrets.adminUser;
      };
    };

    # X11VNC server configuration
    systemd.services.x11vnc = {
      description = "X11VNC Remote Desktop Server";
      after = ["display-manager.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.x11vnc}/bin/x11vnc -display :0 -forever -shared \
            -rfbport 5900 -no6 -auth guess -noxdamage -repeat
        '';
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Additional packages for remote desktop
    environment.systemPackages = with pkgs; [
      x11vnc
      xfce.thunar
      xfce.xfce4-terminal
      xfce.xfce4-taskmanager
    ];

    # Open VNC port in firewall
    networking.firewall.allowedTCPPorts = [5900];

    # Enable dbus for XFCE
    services.dbus.enable = true;
  };
}
