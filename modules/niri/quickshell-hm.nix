{ config, pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
    inter
    material-design-icons
    nerd-fonts.jetbrains-mono
    python3Packages.pywal
  ];

  xdg.configFile."quickshell" = {
    source = inputs.qs-theme;
    recursive = true;
  };
}
