{ config, pkgs, inputs, ... }:
let
  # On non-NixOS hosts home-manager provides a nixGL wrapper; on NixOS this is a no-op.
  glWrap = config.lib.nixGL.wrap or (p: p);
in
{
  home.packages = with pkgs; [
    (glWrap inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default)
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
