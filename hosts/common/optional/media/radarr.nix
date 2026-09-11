{ config, lib, pkgs, ... }:

{

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 7878 ];

  services.radarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/radarr";
  };

  users.groups.media = {};

  backups.restic.sources = [ config.services.radarr.dataDir ];
}