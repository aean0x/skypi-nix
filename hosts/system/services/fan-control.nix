{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.rock5b-fan-control = {
    enable = lib.mkEnableOption "Rock 5B fan control";
    package = lib.mkPackageOption pkgs "fan-control-rock5b" {};
    settings = lib.mkOption {
      description = "Fan control settings for Rock 5B NAS";
      type = lib.types.attrs;
      default = {
        pwmchip = -1;
        gpio = 0;
        pwm-period = 10000;
        temp-map = [
          {
            temp = 38;
            duty = 0;
            duration = 20;
          }
          {
            temp = 42;
            duty = 55;
            duration = 25;
          }
          {
            temp = 47;
            duty = 65;
            duration = 35;
          }
          {
            temp = 52;
            duty = 75;
            duration = 45;
          }
          {
            temp = 57;
            duty = 85;
            duration = 60;
          }
          {
            temp = 62;
            duty = 95;
            duration = 120;
          }
          {
            temp = 65;
            duty = 100;
            duration = 180;
          }
        ];
      };
    };
  };

  config = lib.mkIf config.services.rock5b-fan-control.enable {
    systemd.services.fan-control = {
      description = "Fan control for Rock 5B NAS";
      after = ["networking.target"];
      wantedBy = ["multi-user.target"];
      startLimitBurst = 0;
      startLimitIntervalSec = 60;
      serviceConfig = {
        Type = "forking";
        PIDFile = "/run/fan-control.pid";
        ExecStart = "${config.services.rock5b-fan-control.package}/bin/fan-control -d -p /run/fan-control.pid";
        Restart = "always";
        RestartSec = "2";
        TimeoutStopSec = "15";
      };
    };

    environment.etc."fan-control.json".text = builtins.toJSON config.services.rock5b-fan-control.settings;
  };
}
