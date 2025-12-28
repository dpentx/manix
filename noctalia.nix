{ pkgs, inputs, ...}:
{
 environment.systemPackages = with pkgs; [
  inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
 ];
# networking.networkManager.enable = true;
 hardware.bluetooth.enable = true;
 services.power-profiles-daemon.enable = true;
 services.upower.enable = true;
}
