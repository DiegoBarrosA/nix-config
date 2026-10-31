{ ... }:
{
  flake.modules.nixos.media-sonarr =
{ config, lib, pkgs, ... }:

{
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "/nix/storage/servarr/sonarr";
  };

  systemd.tmpfiles.settings."10-sonarr".${config.services.sonarr.dataDir}.d = {
    user = "media";
    group = "media";
    mode = "0700";
  };

  backups.restic.sources = [ config.services.sonarr.dataDir ];
}
  ;
}
