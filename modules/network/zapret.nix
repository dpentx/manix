{ pkgs,config, ...}:

{
 networking = {
    nameservers = ["127.0.0.1" "::1" "1.1.1.1" "8.8.8.8" ];
  };

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = ["127.0.0.1:53" "[::1]:53"];
    };
  };

  services.zapret = {
    enable = true;
    params = [
      "--dpi-desync=fake"
      "--dpi-desync-ttl=8"
    ];
  };
}
