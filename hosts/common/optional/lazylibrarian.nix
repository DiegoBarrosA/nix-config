{ config, lib, pkgs, customPkgs, ... }:

{
  # LazyLibrarian - Book automation (ebooks, audiobooks, magazines)
  # Port 5299 - Web UI

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 5299 ];

  systemd.services.lazylibrarian = {
    description = "LazyLibrarian - Book automation";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "diego";
      Group = "media";
      WorkingDirectory = "/nix/storage/lazylibrarian";
      ExecStart = "${customPkgs.lazylibrarian}/bin/lazylibrarian --datadir=/nix/storage/lazylibrarian --nolaunch --port=5299";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  users.groups.media = {};
}
