{ config, pkgs, lib, inputs, ... }:
{
  home.username = "asus";
  home.homeDirectory = "/home/asus";
  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  imports = [
    ./modules/quickshell-hm.nix
    ./modules/shell.nix
    ./modules/terminal.nix
  ];

  home.packages = with pkgs; [
    nautilus
    hyprshot
    pamixer
    nordzy-cursor-theme
    microsoft-edge
    prismlauncher
    github-desktop
    papirus-icon-theme
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_THEME = "catppuccin-mocha-peach-standard+default";
  };

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-peach-standard+default";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "peach" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Noto Sans";
      size = 11;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  home.pointerCursor = {
    name = "Nordzy-catppuccin-mocha-peach";
    package = pkgs.nordzy-cursor-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  systemd.user.startServices = "sd-switch";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # ─── Niri yapılandırması ──────────────────────────────────────────────────
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "tr"
                variant "intl"
            }
            repeat-delay 300
            repeat-rate 50
        }

        touchpad {
            tap
            natural-scroll
            tap-button-map "left-right-middle"
            scroll-method "two-finger"
        }

        mouse {
        }
    }

    layout {
        gaps 8
        center-focused-column "never"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
            proportion 1.0
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            off
        }

        border {
            width 2
            active-color "#E69875"
            inactive-color "#3D4A56"
        }

        struts {
            top 0
            bottom 0
        }
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    environment {
        DISPLAY ":1"
        NIXOS_OZONE_WL "1"
        QT_QPA_PLATFORM "wayland"
        MOZ_ENABLE_WAYLAND "1"
    }

    spawn-at-startup "systemctl" "--user" "import-environment" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
    spawn-at-startup "swww-daemon"
    spawn-at-startup "sh" "-c" "pgrep -x quickshell || quickshell"

    binds {
        Mod+Return  { spawn "kitty"; }
        Mod+A       { spawn "sh" "-c" "touch /tmp/qs-toggle"; }
        Mod+Q       { close-window; }
        Mod+Shift+E { quit skip-confirmation=true; }

        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }

        Mod+R       { switch-preset-column-width; }
        Mod+F       { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }

        Print           { screenshot; }
        Mod+Print       { screenshot-screen; }
        Mod+Shift+Print { screenshot-window; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn "pamixer" "--increase" "5"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "pamixer" "--decrease" "5"; }
        XF86AudioMute        allow-when-locked=true { spawn "pamixer" "--toggle-mute"; }
        XF86AudioPlay        allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioNext        allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev        allow-when-locked=true { spawn "playerctl" "previous"; }
    }

    window-rule {
        match app-id="steam"
        default-column-width { proportion 0.8; }
    }

    window-rule {
        match app-id="steam" title="^Steam$"
        default-column-width { proportion 1.0; }
    }

    window-rule {
        match app-id="org.gnome.Nautilus"
        default-column-width { proportion 0.5; }
    }
  '';
}
