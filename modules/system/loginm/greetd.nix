{ config, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "asus";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/tuigreet 0755 asus asus -"
  ];

  security.pam.services.greetd = {};
}
