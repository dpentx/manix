{ config, pkgs, lib, inputs, ... }:
{
  home.username = "asus";
  home.homeDirectory = "/home/asus";
  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  imports = [
    # ✅ noctalia kaldırıldı, quickshell modülü eklendi
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
    vscode
    python315
    prismlauncher
    kdePackages.audiotube
    github-desktop
    papirus-icon-theme
    catppuccin-gtk
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
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    layout {
        gaps 8
        center-focused-column "never"
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    environment {
        DISPLAY ":1"
    }

    spawn-at-startup "systemctl" "--user" "import-environment" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"

    // ✅ noctalia-shell yerine quickshell
    spawn-at-startup "sh" "-c" "pgrep -x quickshell || quickshell"

    binds {
        Mod+Return { spawn "kitty"; }

        // ✅ Mod+D fuzzel açmak yerine artık kullanılmıyor (quickshell içinde)
        // Launcher'ı quickshell IPC üzerinden aç:
        Mod+A { spawn "sh" "-c" "touch /tmp/qs-toggle"; }

        Mod+Q { close-window; }

        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Right { move-column-right; }

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

        Mod+Shift+E { quit; }

        Print { screenshot; }
        Mod+Print { screenshot-screen; }
        Mod+Shift+Print { screenshot-window; }
    }

    window-rule {
        match app-id="steam"
        default-column-width { proportion 0.8; }
    }

    window-rule {
        match app-id="steam" title="^Steam$"
        default-column-width { proportion 1.0; }
    }
  '';
}
