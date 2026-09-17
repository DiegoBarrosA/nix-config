{ config, lib, pkgs, ... }:

{
  systemd.services.setup-media-directories = {
    description = "Setup unified media directories with proper permissions";
    wantedBy = [ "multi-user.target" ];
    before = [
      "sonarr.service"
      "radarr.service"
      "lidarr.service"
      "prowlarr.service"
      "lazylibrarian.service"
      "calibre-server.service"
      "calibre-web.service"
      "bazarr.service"
      "jellyfin.service"
      "qbittorrent.service"
      "tdarr-server.service"
      "tdarr-node-main.service"
      "media-jellyseerr.service"
      "aria2.service"
      "samba-smbd.service"
    ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 60;
    };
    script = ''
      set -e
      echo "[media-setup] Creating unified media directory structure..."

      mkdir -p /srv/media/library/{movies,series,music,books,audiobooks}
      mkdir -p /srv/media/downloads/complete/{movies,series,lidarr,lazylibrarian,bazarr}
      mkdir -p /srv/media/downloads/incomplete
      mkdir -p /srv/media/{Incoming,Documents,Obsidian,Repos,Archive,Pictures}
      mkdir -p /srv/media/Pictures/{Wallpapers,Photos,Screenshots}

      mkdir -p /nix/storage/{tdarr,qbittorrent,jellyseerr}
      mkdir -p /nix/storage/servarr/{sonarr,radarr,lidarr,bazarr,prowlarr}

      echo "[media-setup] Setting ownership and permissions..."

      chown -R media:media /srv/media
      chown -R media:media /nix/storage/{tdarr,qbittorrent,jellyseerr}
      chown -R media:media /nix/storage/servarr

      chmod 755 /srv/media
      chmod -R 750 /srv/media/library
      chmod -R 750 /srv/media/downloads
      chmod 750 /srv/media/{Incoming,Documents,Obsidian,Repos,Archive,Pictures}
      chmod -R 750 /nix/storage/{tdarr,qbittorrent,jellyseerr}
      chmod 750 /nix/storage/servarr

      echo "[media-setup] Directory structure created successfully:"
      echo "  Library: /srv/media/library/{movies,series,music,books,audiobooks}"
      echo "  Sync:    /srv/media/{Documents,Obsidian,Repos,Pictures}"
      echo "  Archive: /srv/media/Archive"
      echo "  Incoming: /srv/media/Incoming"
      echo "  Downloads: /srv/media/downloads/{complete,incomplete}"
      echo ""
      echo "All directories owned by media:media with proper permissions"

      ls -la /srv/media/
      ls -la /srv/media/library/
      ls -la /srv/media/downloads/
    '';
  };

  systemd.tmpfiles.rules = [
    "d /srv/media 0755 media media -"
    "d /srv/media/library 0750 media media -"
    "d /srv/media/library/movies 0750 media media -"
    "d /srv/media/library/series 0750 media media -"
    "d /srv/media/library/music 0750 media media -"
    "d /srv/media/library/books 0750 media media -"
    "d /srv/media/library/audiobooks 0750 media media -"

    "d /srv/media/downloads 0750 media media -"
    "d /srv/media/downloads/complete 0750 media media -"
    "d /srv/media/downloads/complete/movies 0750 media media -"
    "d /srv/media/downloads/complete/series 0750 media media -"
    "d /srv/media/downloads/complete/lidarr 0750 media media -"
    "d /srv/media/downloads/complete/lazylibrarian 0750 media media -"
    "d /srv/media/downloads/complete/bazarr 0750 media media -"
    "d /srv/media/downloads/incomplete 0750 media media -"

    "d /srv/media/Incoming 0750 media media -"
    "d /srv/media/Documents 0750 media media -"
    "d /srv/media/Obsidian 0750 media media -"
    "d /srv/media/Repos 0750 media media -"
    "d /srv/media/Archive 0750 media media -"
    "d /srv/media/Pictures 0750 media media -"
    "d /srv/media/Pictures/Wallpapers 0750 media media -"
    "d /srv/media/Pictures/Photos 0750 media media -"
    "d /srv/media/Pictures/Screenshots 0750 media media -"

    "d /nix/storage/servarr 0750 media media -"
    "d /nix/storage/servarr/sonarr 0750 media media -"
    "d /nix/storage/servarr/radarr 0750 media media -"
    "d /nix/storage/servarr/lidarr 0750 media media -"
    "d /nix/storage/servarr/bazarr 0750 media media -"
    "d /nix/storage/servarr/prowlarr 0750 media media -"
    "d /nix/storage/tdarr 0750 media media -"
    "d /nix/storage/qbittorrent 0750 media media -"
    "d /nix/storage/jellyseerr 0770 media media -"
  ];

  environment.variables = {
    MEDIA_ROOT = "/srv/media";
    LIBRARY_PATH = "/srv/media/library";
    MOVIES_PATH = "/srv/media/library/movies";
    TV_PATH = "/srv/media/library/series";
    MUSIC_PATH = "/srv/media/library/music";
    BOOKS_PATH = "/srv/media/library/books";
    AUDIOBOOKS_PATH = "/srv/media/library/audiobooks";
    DOWNLOADS_PATH = "/srv/media/downloads";
    INCOMING_PATH = "/srv/media/Incoming";
    DOCUMENTS_PATH = "/srv/media/Documents";
    OBSIDIAN_PATH = "/srv/media/Obsidian";
    REPOS_PATH = "/srv/media/Repos";
    ARCHIVE_PATH = "/srv/media/Archive";
    PICTURES_PATH = "/srv/media/Pictures";
    TDARR_DATA = "/nix/storage/tdarr";
  };
}