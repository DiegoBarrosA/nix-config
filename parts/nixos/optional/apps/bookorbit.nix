{ ... }:
{
  flake.modules.nixos.apps-bookorbit =
{ config, lib, ... }:

{
  sops.secrets."bookorbit-jwt-secret" = { };
  sops.secrets."bookorbit-setup-token" = { };
  sops.secrets."bookorbit-request-encryption-key" = { };

  sops.templates."bookorbit.env".content = ''
    JWT_SECRET=${config.sops.placeholder."bookorbit-jwt-secret"}
    SETUP_BOOTSTRAP_TOKEN=${config.sops.placeholder."bookorbit-setup-token"}
    BOOK_REQUEST_ENCRYPTION_KEY=${config.sops.placeholder."bookorbit-request-encryption-key"}
  '';

  services.bookorbit = {
    enable = true;
    # media owns /srv/media and setup-media-directories re-chowns it on every
    # boot, so running as media is the only way to keep write access to the
    # library and dock.
    user = "media";
    group = "media";
    environmentFile = config.sops.templates."bookorbit.env".path;
    environment = {
      PORT = 8090;
      HOST = "0.0.0.0";
      APP_URL = "https://bookorbit.minerales.network";
      APP_DATA_PATH = "/nix/storage/bookorbit";
      # Same filesystem as downloads/complete so the dock can be fed by reflink copy.
      BOOK_DOCK_PATH = "/srv/media/Incoming/bookorbit-dock";
      TZ = config.time.timeZone;
    };
  };

  # The module hardcodes the DB role "bookorbit" over the unix socket; map the
  # media OS user onto it, otherwise peer auth rejects the connection.
  services.postgresql = {
    identMap = "bookorbit media bookorbit";
    authentication = lib.mkBefore "local bookorbit bookorbit peer map=bookorbit\n";
  };

  systemd.tmpfiles.rules = [
    "d /nix/storage/bookorbit 0750 media media -"
    "d /srv/media/library/lightnovels 0750 media media -"
    "d /srv/media/Incoming/bookorbit-dock 0750 media media -"
  ];

  backups.restic.sources = [ "/nix/storage/bookorbit" ];
}
  ;
}
