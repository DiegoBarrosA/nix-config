
{ config, pkgs, ... }:
{
    systemd.services.transmission = {
    after = [ "network-online.target" "mnt-media.mount" ];
    requires = [ "network-online.target" "mnt-media.mount" ];
  };
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    openFirewall = true;
    openRPCPort = true;
    settings = {
      download-dir = "/mnt/media/Transmission/Downloads";
      incomplete-dir = "/mnt/media/Transmission/Incomplete";
      watch-dir = "/mnt/media/Transmission/Watch";
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-whitelist-enabled = false;
      rpc-whitelist = "127.0.0.1,sonarr.minerales.network,radarr.minerales.network,prowlarr.minerales.network";
      rpc-host-whitelist = "transmission.minerales.network,sonarr.minerales.network";
      rpc-authentication-required = false;
      umask = 2;
      peer-port = 51413;
      peer-port-random-on-start = false;
        #   rpc-url = "/transmission/rpc";
    };
    user = "diego";
    group = "media";

  };
  networking.firewall.allowedTCPPorts = [ 9091 51413 ];
  networking.firewall.allowedUDPPorts = [ 51413 ];
}