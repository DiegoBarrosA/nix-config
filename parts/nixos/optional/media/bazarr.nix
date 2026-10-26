{ ... }:
{
  flake.modules.nixos.media-bazarr =
{ config, lib, pkgs, ... }:

{
  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  # Provider credentials, language profiles and the subtitle history. The other
  # *arr apps were already covered; bazarr was the one left out.
  backups.restic.sources = [ "/var/lib/bazarr" ];
}
  ;
}
