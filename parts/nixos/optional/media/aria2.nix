{ ... }:
{
  flake.modules.nixos.media-aria2 =
{ config, lib, pkgs, ... }:

{

  services.aria2 = {
    enable = true;
    rpcSecretFile = config.sops.secrets."aria2-rpc-secret".path;
    openPorts = false;
    serviceUMask = "0002";
    downloadDirPermission = "0775";
    settings = {
      dir = "/srv/media/downloads/aria2";
      "rpc-listen-port" = 6800;
      "rpc-listen-all" = true;
      "rpc-allow-origin-all" = true;
      "listen-port" = [
        {
          from = 6881;
          to = 6999;
        }
      ];
      "max-concurrent-downloads" = 5;
      "max-connection-per-server" = 16;
      "split" = 16;
      "continue" = true;
      "auto-file-renaming" = false;
      "allow-overwrite" = true;
    };
  };

  users.users.diego.extraGroups = [ "aria2" ];

  systemd.tmpfiles.rules = [
    "d /srv/media/downloads/aria2 0775 media aria2 -"
  ];

}

  ;
}
