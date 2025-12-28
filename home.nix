{ config, pkgs, lib, inputs, ... }:
{

 home.username = "asus";
 home.homeDirectory = "/home/asus";
 home.stateVersion = "25.11";
 home.enableNixpkgsReleaseCheck = false;

 imports = [
  inputs.noctalia.homeModules.default
  ];

    programs.noctalia-shell = {
      enable = true;
      settings = {
        # configure noctalia here
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
          avatarImage = "/home/drfoobar/.face";
          radiusRatio = 0.2;
        };
        location = {
          monthBeforeDay = true;
          name = "Marseille, France";
        };
      };
    };

# programs.caelestia = {
#  enable = true;
#  systemd = {
#   enable = true;
#   target = "graphical-session-target";
#   environment = [];
#  };
#  settings = {
#   bar.status = {
#    showBattery = false;
#   };
#  paths.wallpaperDir = "~/Images";
#  };
#  cli = {
#   enable = true;
#   settings = {
#    theme.enableGtk = false;
#   };
#  };
# };


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
 ];

 programs.home-manager.enable = true;

 programs.bash.enable = true;
 programs.bash.sessionVariables = {
   LANG = "C";
   LC_ALL = "C";
 };

 home.sessionVariables = {
   NIXOS_OZONE_WL = "1";
 };


 home.pointerCursor = {
  name = "Nordzy-catppuccin-latte-peach";
  package = pkgs.nordzy-cursor-theme;
  size = 20;
  gtk.enable = true;
  x11.enable = true;
 };

}
