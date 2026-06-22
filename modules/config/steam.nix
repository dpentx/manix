{ config, pkgs, ... }:

{
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  localNetworkGameTransfers.openFirewall = true;

  package = pkgs.steam.override {
     extraEnv = {
       GDK_BACKEND = "x11";
       __NV_PRIME_RENDER_OFFLOAD = "1";
       __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
 };
};

}
