{ config, pkgs, ... }:

{
  #### greetd servisi ####
  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        user = "asus";
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --cmd /etc/greetd/niri-session
        '';
      };
    };
  };

  #### Niri session wrapper (ENV yükleyen script) ####
  environment.etc."greetd/niri-session" = {
    text = ''
      #!/usr/bin/env bash

      # Home Manager session variables
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi

      # Wayland / Chromium / Electron
      export NIXOS_OZONE_WL=1
      export MOZ_ENABLE_WAYLAND=1
      export QT_QPA_PLATFORM=wayland
      export XDG_SESSION_TYPE=wayland

      exec niri
    '';
    mode = "0755";
  };

  #### PAM (greetd için gerekli) ####
  security.pam.services.greetd = {};
}
