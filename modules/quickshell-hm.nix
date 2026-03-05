{ config, pkgs, inputs, ... }:

# modules/quickshell-hm.nix

{
  home.packages = [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile = {
    "quickshell/shell.qml".source            = ../qs/shell.qml;
    "quickshell/TopBar.qml".source           = ../qs/TopBar.qml;
    "quickshell/LauncherOverlay.qml".source  = ../qs/LauncherOverlay.qml;
    "quickshell/modules/Clock.qml".source        = ../qs/modules/Clock.qml;
    "quickshell/modules/Workspaces.qml".source   = ../qs/modules/Workspaces.qml;
    "quickshell/modules/StatusIcons.qml".source  = ../qs/modules/StatusIcons.qml;
    "quickshell/Wallhaven.qml".source = ../qs/wallhaven.qml;
  };
}
