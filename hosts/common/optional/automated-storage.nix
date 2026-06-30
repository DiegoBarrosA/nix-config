{ config, lib, pkgs, ... }:

{
  # Automated storage setup - runs on every boot
  system.activationScripts.cobalto-storage = {
    text = ''
      # Create all necessary directories
      mkdir -p /nix/storage/{run/secrets,secrets,llm,syncthing,transmission,jellyfin,homepage}
      mkdir -p /mnt/media/{Movies,Tv,Music,Books,Incoming,Documents,Obsidian,Repos,Archive,Pictures}
      mkdir -p /mnt/media/Pictures/{Wallpapers,Photos,Screenshots}
      mkdir -p /nix/storage/var/lib/vols/{portainer,watchtower}
      
      # Create container-specific directories
      mkdir -p /nix/storage/syncthing/{config,data}
      mkdir -p /mnt/media/Transmission/{Downloads,Watch,Incomplete}
      mkdir -p /nix/storage/jellyfin/{config,cache}
      mkdir -p /nix/storage/llm/models
      
      # Set ownership and permissions
      chown -R 1000:1000 /nix/storage/syncthing
      chown -R 1000:1000 /mnt/media/Transmission  
      chown -R 1000:1000 /nix/storage/jellyfin
      chown -R 1000:1000 /nix/storage/homepage
      chown -R 1000:1000 /nix/storage/llm
      
      # Media directories - readable by media group
      # NOTE: chgrp -R users /mnt/media commented out because it takes hours on 115GB
      chmod -R 755 /nix/storage/var/lib/vols || true
      
      # Ensure secrets directory has correct permissions
      chmod 700 /nix/storage/run/secrets 2>/dev/null || true
      chmod 600 /nix/storage/run/secrets/* 2>/dev/null || true
    '';
    deps = [ "users" "groups" ];
  };

  # Systemd tmpfiles for additional runtime directories
  systemd.tmpfiles.rules = [
    "d /var/log/containers 0755 root root -"
    "d /run/containers 0755 root root -"
    "d /tmp/containers-diego 0755 diego users -"
  ];
}