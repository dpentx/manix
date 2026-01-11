{ config, pkgs, lib, inputs, ... }:
{
  home.username = "asus";
  home.homeDirectory = "/home/asus";
  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  imports = [
    inputs.noctalia.homeModules.default
    ./modules/shell.nix
    ./modules/terminal.nix
  ];

  programs.noctalia-shell = {
    enable = true;
    settings = {
      bar = {
        density = "compact";
        position = "right";
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Monochrome";
      general = {
        avatarImage = "/home/asus/.face";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "Van, Turkey";
      };
    };
  };

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
    # Tema paketleri
    papirus-icon-theme
    catppuccin-gtk
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_THEME = "catppuccin-mocha-peach-standard+default";
  };

  # GTK teması
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
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt teması (Steam gibi uygulamalar için)
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

  # XDG user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # Systemd user services
  systemd.user.startServices = "sd-switch";
  
  # XDG Portal ayarları
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = "gtk";
      };
   };
  };
  
  # GNOME Keyring
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

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
        DISPLAY ":0"
    }

    spawn-at-startup "systemctl" "--user" "import-environment" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
    spawn-at-startup "sh" "-c" "pgrep -x noctalia-shell || noctalia-shell"

    binds {
        Mod+Return { spawn "kitty"; }
        Mod+D { spawn "fuzzel"; }
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
