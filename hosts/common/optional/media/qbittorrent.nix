{ config, lib, pkgs, ... }:

let
  mediaRoot = "/srv/media";
in
{

  users.groups.media = { };

  services.qbittorrent = {
    enable = true;
    user = "media";
    group = "media";

    webuiPort = 8080;
    torrentingPort = 51413;
    openFirewall = false;

    profileDir = "/nix/storage/qbittorrent";

    serverConfig = {
      LegalNotice.Accepted = true;

      Preferences = {
        WebUI = {
          Username = "admin";
          Port = 8080;
        };
        "Session\\DefaultSavePath" = "${mediaRoot}/downloads";
        "Session\\TempPath" = "${mediaRoot}/downloads";
        "Downloads\\TempPath" = "${mediaRoot}/downloads";
        "Downloads\\SavePath" = "${mediaRoot}/downloads";
        "Downloads\\TempPathEnabled" = true;
        "Downloads\\UseCategoryFolders" = true;
        General = {
          Locale = "en_US";
        };
      };

    };
  };

  systemd.services.qbittorrent-setup = {
    description = "Setup qBittorrent directories for Servarr integration";
    wantedBy = [ "multi-user.target" ];
    before = [ "qbittorrent.service" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo "[qbittorrent] Setting up directories..."

      mkdir -p ${mediaRoot}/downloads/complete/{movies,series,lidarr,lazylibrarian,bazarr}
      mkdir -p ${mediaRoot}/downloads/incomplete
      mkdir -p /nix/storage/qbittorrent

      chown -R media:media ${mediaRoot}/downloads
      chown -R media:media /nix/storage/qbittorrent
      chmod -R 755 /nix/storage/qbittorrent

      echo "[qbittorrent] Directories ready:"
      echo "  - Downloads: ${mediaRoot}/downloads/"
      echo "  - Complete:  ${mediaRoot}/downloads/complete/"
      echo "  - Categories: movies, series, lidarr, lazylibrarian, bazarr"
    '';
  };

}
