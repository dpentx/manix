{ config, pkgs, inputs, ... }:
let
  # nixGL wrapper on non-NixOS hosts (see home/manjaro.nix); a no-op elsewhere.
  glWrap = config.lib.nixGL.wrap or (p: p);
in
{
  imports = [ inputs.qs-niri.homeManagerModules.default ];

  # The shell from github:dpentx/qs-niri via its own module: it installs wl-clipboard, playerctl, brightnessctl,
  # grim, slurp, matugen, cliphist, qrencode, gpu-screen-recorder, wlsunset ... (by profile) and writes
  # ~/.config/quickshell, so nothing is copied by hand here.
  programs.qs-niri = {
    enable = true;
    profile = "bloated";
    quickshell = glWrap inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # niri starts the shell itself (spawn-at-startup in modules/niri/niri.nix), a user service would race it
    autostart = false;
    # settings = { launcher.favorites = [ "firefox" "kitty" ]; };   # becomes ~/.config/quickshell/shell.json
  };

  home.packages = with pkgs; [
    inter
    material-design-icons
    nerd-fonts.jetbrains-mono
  ];
}
