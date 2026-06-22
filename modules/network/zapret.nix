{ pkgs, config, ... }:

{
  networking = {
    nameservers = [ "127.0.0.1" "::1" "1.1.1.1" ];
    resolvconf.extraConfig = ''
      name_servers="127.0.0.1 ::1 1.1.1.1"
      resolv_conf_options="trust-ad"
    '';
   };

  networking.networkmanager.dns = "default";

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];
    };
  };

  services.zapret = {
    enable = true;
    params = [
      "--dpi-desync=fake"
      "--dpi-desync-ttl=3"
      "--dpi-desync-fooling=md5sig,badseq"
      "--dpi-desync-split-pos=method+2"
    ];
  };
}
