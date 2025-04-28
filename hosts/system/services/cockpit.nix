{
  config,
  pkgs,
  ...
}: {
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        AllowUnencrypted = false;
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cockpit
  ];

  # Enable required system services
  services.udisks2.enable = true;

  # Additional security settings for Cockpit
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.cockpit-project") === 0 &&
          subject.local && subject.active && subject.isInGroup("wheel")) {
          return polkit.Result.YES;
      }
    });
  '';
}
