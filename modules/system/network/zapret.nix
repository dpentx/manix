{ pkgs, config, ... }:

{
  networking = {
    nameservers = [ "1.1.1.1" "127.0.0.1" ];
    resolvconf.extraConfig = ''
      name_servers="1.1.1.1 127.0.0.1"
      resolv_conf_options="trust-ad"
      resolv_conf_local_only="NO"
    '';
  };

  networking.networkmanager.dns = "none";

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];

      bootstrap_resolvers = [ "1.1.1.1:53" "9.9.9.9:53" ];
      ignore_system_dns = true;
    };
  };

  systemd.services.dnscrypt-proxy = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig.TimeoutStartSec = "15";
  };

  services.zapret = {
    enable = true;
    params = [
      "--dpi-desync=fakedsplit" 
      "--dpi-desync-fooling=badseq" 
      "--dpi-desync-badseq-increment=0" 
      "--dpi-desync-split-pos=method+2"
    ];
  };
}
