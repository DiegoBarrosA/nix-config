{ config, lib, pkgs, ... }:

{

  system.activationScripts.cobalto-storage = {
    text = ''

      mkdir -p /nix/storage/{run/secrets,secrets,llm,syncthing,transmission,jellyfin,homepage}
      mkdir -p /mnt/media/{Movies,Tv,Music,Books,Incoming,Documents,Obsidian,Repos,Archive,Pictures}
      mkdir -p /mnt/media/Pictures/{Wallpapers,Photos,Screenshots}
      mkdir -p /nix/storage/var/lib/vols/{portainer,watchtower}

      mkdir -p /nix/storage/syncthing/{config,data}
      mkdir -p /mnt/media/Transmission/{Downloads,Watch,Incomplete}
      mkdir -p /nix/storage/jellyfin/{config,cache}
      mkdir -p /nix/storage/llm/models

      chown -R 1000:1000 /nix/storage/syncthing
      chown -R 1000:1000 /mnt/media/Transmission
      chown -R 1000:1000 /nix/storage/jellyfin
      chown -R 1000:1000 /nix/storage/homepage
      chown -R 1000:1000 /nix/storage/llm

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