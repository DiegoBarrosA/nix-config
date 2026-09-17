{
  config,
  lib,
  pkgs,
  ...
}:

let
  news = pkgs.fetchNextcloudApp {
    url = "https://github.com/nextcloud/news/releases/download/28.0.1/news.tar.gz";
    sha256 = "1q1j8yrgsgrfanjwxl31k2l325nxgf3zdqfdpn84mgdz343z0z77";
    license = "agpl3Plus";
  };
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "cloud.minerales.network";
    home = "/nix/storage/nextcloud";

    https = true;

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass";
    };

    database.createLocally = true;
    configureRedis = true;

    maxUploadSize = "1G";

    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit
        calendar
        contacts
        tasks
        notes
        deck
        bookmarks
        ;
      inherit news;
    };
    extraAppsEnable = true;

    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
    };
  };

  services.nginx.virtualHosts."cloud.minerales.network" = {
    forceSSL = true;
    useACMEHost = "minerales.network";
  };

  systemd.tmpfiles.rules = [
    "d /nix/storage/nextcloud 0750 nextcloud nextcloud -"
  ];

  # User files and config. The database is postgres and is covered separately
  # by the pg_dump in system/postgres-backup.nix.
  backups.restic.sources = [ "/nix/storage/nextcloud" ];

  environment.etc."nextcloud-admin-pass".text = "admin";
}
