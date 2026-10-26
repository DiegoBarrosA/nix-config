{ ... }:
{
  flake.modules.nixos.media-lidarr =
{ config, lib, pkgs, ... }:

{
  services.lidarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "/nix/storage/servarr/lidarr";
  };

  backups.restic.sources = [ config.services.lidarr.dataDir ];
}
  ;
}
