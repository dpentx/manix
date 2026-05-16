{ config, pkgs, lib, inputs, ... }:
{
  home.username = "asus";
  home.homeDirectory = "/home/asus";
  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  imports = [
    ../modules/niri/quickshell-hm.nix
    ../modules/config/shell.nix
    ../modules/config/terminal.nix
    ../modules/niri/niri.nix
    ../modules/config/gtk.nix
  ];

  home.packages = with pkgs; [
    nautilus
    hyprshot
    pamixer
    nordzy-cursor-theme
    microsoft-edge
    prismlauncher
    github-desktop
    pear-desktop
    onlyoffice-desktopeditors
    swaylock
    wl-clipboard
    libnotify
    wf-recorder
    lxqt.lxqt-policykit
  ];

  programs.home-manager.enable = true;

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };
}
