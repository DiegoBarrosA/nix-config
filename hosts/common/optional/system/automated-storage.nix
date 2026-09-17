{ config, lib, pkgs, ... }:

{

  system.activationScripts.cobalto-storage = {
    text = ''
      mkdir -p /nix/storage/{run/secrets,secrets,llm,syncthing,tdarr,qbittorrent,jellyseerr,jellyfin,homepage}
      mkdir -p /nix/storage/lazylibrarian
      mkdir -p /srv/media/library/{movies,series,music,books,audiobooks}
      mkdir -p /srv/media/downloads/{complete,incomplete}
      mkdir -p /srv/media/{Incoming,Documents,Obsidian,Repos,Archive,Pictures}
      mkdir -p /srv/media/Pictures/{Wallpapers,Photos,Screenshots}
      mkdir -p /nix/storage/var/lib/vols/{portainer,watchtower}

      mkdir -p /nix/storage/syncthing/{config,data}
      mkdir -p /nix/storage/jellyfin/{config,cache}
      mkdir -p /nix/storage/llm/models

      chown -R media:media /nix/storage/syncthing
      chown -R media:media /srv/media
      chown -R media:media /nix/storage/jellyfin
      chown -R media:media /nix/storage/homepage
      chown -R media:media /nix/storage/llm
      # lazylibrarian runs as media:media and refuses to start if its datadir
      # is not writable.
      chown -R media:media /nix/storage/lazylibrarian

      # zennotes serves this vault as uid 1000 (diego), but the blanket
      # "chown -R media:media /srv/media" above would otherwise lock it out.
      # Keep this after that chown.
      chown -R diego:users /srv/media/Obsidian

      chmod -R 755 /nix/storage/var/lib/vols || true

      chmod 700 /nix/storage/run/secrets 2>/dev/null || true
      chmod 600 /nix/storage/run/secrets/* 2>/dev/null || true
    '';
    deps = [ "users" "groups" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/log/containers 0755 root root -"
    "d /run/containers 0755 root root -"
    "d /tmp/containers-diego 0755 diego users -"
  ];
}