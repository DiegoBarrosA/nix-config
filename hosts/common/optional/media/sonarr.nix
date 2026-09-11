{ config, lib, pkgs, ... }:

{

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 8989 ];

  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/sonarr";
  };

  users.groups.media = {};

  systemd.tmpfiles.settings."10-sonarr".${config.services.sonarr.dataDir}.d = {
    user = "diego";
    group = "media";
    mode = "0700";
  };

  backups.restic.sources = [ config.services.sonarr.dataDir ];
}