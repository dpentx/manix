{ config, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "asus";
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --cmd niri-session
        '';
      };
    };
  };

  environment.etc."greetd/niri-session" = {
    text = ''
      #!/usr/bin/env bash
      
      # Home Manager variables
      [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] && \
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      
      # Wayland + XWayland env vars
      export NIXOS_OZONE_WL=1
      export MOZ_ENABLE_WAYLAND=1
      export QT_QPA_PLATFORM=wayland
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=niri
      
      # XWayland için gerekli
      export DISPLAY=:0
      export GDK_BACKEND=wayland,x11
      
      # DBus ve systemd
      systemctl --user import-environment PATH DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      dbus-update-activation-environment --systemd --all
      
      exec niri-session
    '';
    mode = "0755";
  };

  security.pam.services.greetd = {};
}
