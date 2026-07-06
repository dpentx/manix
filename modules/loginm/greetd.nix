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

  # --remember tuigreet, /var/cache/tuigreet'e yazmak zorunda. Bu dizin normalde
  # otomatik oluşan "greeter" kullanıcısına ait oluyor; ama default_session.user
  # "asus" olduğu için "asus" o dizine yazamıyor ve tuigreet başlarken çöküyor.
  # (bkz. NixOS/nixpkgs#248323)
  systemd.tmpfiles.rules = [
    "d /var/cache/tuigreet 0755 asus asus -"
  ];

  security.pam.services.greetd = {};
}
