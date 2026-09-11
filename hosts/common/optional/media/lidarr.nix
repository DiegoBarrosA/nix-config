{ config, lib, pkgs, ... }:

{

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 8686 ];

  services.lidarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/lidarr";
  };

  users.groups.media = {};

  backups.restic.sources = [ config.services.lidarr.dataDir ];
}