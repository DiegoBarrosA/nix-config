{ ... }:
{
  flake.modules.nixos.media-radarr =
{ config, lib, pkgs, ... }:

{
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "/nix/storage/servarr/radarr";
  };

  backups.restic.sources = [ config.services.radarr.dataDir ];
}
  ;
}
