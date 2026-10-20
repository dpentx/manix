{ config, pkgs, lib, inputs, ... }:

# Manjaro host: Nix + standalone home-manager on top of a normal Arch-based system.
# The compositor and session come from pacman (see README); everything user-level
# (niri config, quickshell, terminal, shell, GTK) comes from the shared modules.
{
  home.username = "asus";   # change to the Manjaro login name if it differs
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  imports = [
    ../modules/niri/quickshell-hm.nix
    ../modules/config/shell.nix
    ../modules/config/terminal.nix
    ../modules/niri/niri.nix
    ../modules/config/gtk.nix
  ];

  targets.genericLinux = {
    enable = true;
    nixGL = {
      packages = inputs.nixgl.packages;
      # Intel/AMD. For NVIDIA see the README (needs --impure and the nixGLNvidia wrapper).
      defaultWrapper = "mesa";
    };
  };

  # Nix-installed fonts must be visible to fontconfig outside NixOS.
  fonts.fontconfig.enable = true;

  # Manjaro ships its own portals; two sets fight over the same D-Bus names.
  xdg.portal.enable = lib.mkForce false;

  programs.zsh.shellAliases.rebuild = lib.mkForce
    "cd ${config.home.homeDirectory}/manix && git add -A && home-manager switch --flake '.#manjaro' -b backup";

  # Graphical apps are wrapped with nixGL; CLI tools are used as they are.
  # Session pieces that need PAM or the GPU driver stack (niri, hyprlock) stay on pacman.
  programs.kitty.package = config.lib.nixGL.wrap pkgs.kitty;

  home.packages = with pkgs; [
    (config.lib.nixGL.wrap nautilus)
    awww
    grim
    slurp
    hyprshot
    pamixer
    playerctl
    brightnessctl
    nordzy-cursor-theme
    wl-clipboard
    cliphist
    swayidle
    libnotify
    wf-recorder
    neovim
    ffmpeg
    git
  ];

  programs.home-manager.enable = true;

  home.file.".config/quickshell-local/scripts/restore-wallpaper.sh" = {
    source = ../modules/niri/scripts/restore-wallpaper.sh;
    executable = true;
  };
}
