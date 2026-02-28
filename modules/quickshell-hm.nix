{ config, pkgs, inputs, ... }:

# modules/quickshell-hm.nix
# Bu dosyayı projenin modules/ klasörüne koy.
# QML dosyalarının ~/manix/qs/ altında olduğunu varsayar.

{
  # Quickshell binary'sini home ortamına ekle
  home.packages = [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # QML kaynaklarını ~/.config/quickshell/ altına semlink olarak koy
  xdg.configFile = {
    "quickshell/shell.qml".source =
      "${config.home.homeDirectory}/manix/qs/shell.qml";
    "quickshell/TopBar.qml".source =
      "${config.home.homeDirectory}/manix/qs/TopBar.qml";
    "quickshell/LauncherOverlay.qml".source =
      "${config.home.homeDirectory}/manix/qs/LauncherOverlay.qml";
    "quickshell/modules/Clock.qml".source =
      "${config.home.homeDirectory}/manix/qs/modules/Clock.qml";
    "quickshell/modules/Workspaces.qml".source =
      "${config.home.homeDirectory}/manix/qs/modules/Workspaces.qml";
    "quickshell/modules/StatusIcons.qml".source =
      "${config.home.homeDirectory}/manix/qs/modules/StatusIcons.qml";
  };
}
