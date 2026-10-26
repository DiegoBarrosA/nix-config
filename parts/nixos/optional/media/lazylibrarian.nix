{ ... }:
{
  flake.modules.nixos.media-lazylibrarian =
{ config, lib, pkgs, customPkgs, ... }:

{
  systemd.services.lazylibrarian = {
    description = "LazyLibrarian - Book automation";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "media";
      Group = "media";
      WorkingDirectory = "/nix/storage/lazylibrarian";
      ExecStart = "${customPkgs.lazylibrarian}/bin/lazylibrarian --datadir=/nix/storage/lazylibrarian --nolaunch --port=5299";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
  ;
}
