{ config, lib, pkgs, ... }:

{
  # Unified media directory configuration for Servarr stack integration
  # This module ensures consistent media directory structure across all services
  
  # Create dedicated media group for shared access
  users.groups.media = {
    gid = 1001;  # Fixed GID for consistency (avoiding conflicts with system groups)
  };
  
  # Ensure diego is in the media group
  users.users.diego.extraGroups = [ "media" ];
  
  # Systemd service to setup media directories before any services start
  systemd.services.setup-media-directories = {
    description = "Setup unified media directories with proper permissions";
    wantedBy = [ "multi-user.target" ];
    before = [
       "sonarr.service"
       "radarr.service"
       "lidarr.service"
       "lazylibrarian.service"
       "calibre-server.service"
       "calibre-web.service"
       "bazarr.service"
      "jellyfin.service"
      "transmission.service"
      "podman-transmission.service"
      "podman-prowlarr.service"
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
      
      # Create main media directories (library + sync + incoming; downloads only under Transmission/)
      mkdir -p /mnt/media/{Movies,Tv,Music,Books,Audiobooks,Incoming,Documents,Obsidian,Repos,Archive,Pictures}
      mkdir -p /mnt/media/Pictures/{Wallpapers,Photos,Screenshots}
      
      # Transmission directories
      mkdir -p /mnt/media/Transmission/{Downloads,Watch,Incomplete}
      
      # Create servarr storage directories  
      mkdir -p /nix/storage/servarr/{sonarr,radarr,lidarr,bazarr,prowlarr}
      mkdir -p /nix/storage/lazylibrarian
      mkdir -p /nix/storage/transmission/config
      
      echo "[media-setup] Setting ownership and permissions..."

      # Non-recursive ownership on root paths only
      chown diego:media /mnt/media /nix/storage/servarr /nix/storage/transmission

      chmod 755 /mnt/media
      chmod 750 /nix/storage/servarr /nix/storage/transmission
      
      echo "[media-setup] Directory structure created successfully:"
      echo "  Library: Movies, Tv, Music, Books, Audiobooks"
      echo "  Sync: Documents, Obsidian, Repos, Archive, Pictures (Wallpapers, Photos, Screenshots)"
      echo "  Incoming: /mnt/media/Incoming"
      echo "  Downloads (only path): /mnt/media/Transmission/Downloads"
      echo "  Watch: /mnt/media/Transmission/Watch"
      echo ""
      echo "All directories owned by diego:media with proper permissions"
      
      # Verify permissions
      ls -la /mnt/media/
      ls -la /mnt/media/Transmission/
    '';
  };
  
  # Create systemd-tmpfiles rules for persistent directory creation
  systemd.tmpfiles.rules = [
    # Media directories (library)
    "d /mnt/media 0755 diego media -"
    "d /mnt/media/Movies 0755 diego media -"
    "d /mnt/media/Tv 0755 diego media -"
    "d /mnt/media/Music 0755 diego media -"
    "d /mnt/media/Books 0755 diego media -"
    "d /mnt/media/Audiobooks 0755 diego media -"
    "d /mnt/media/Incoming 0755 diego media -"
    # Sync directories (Syncthing)
    "d /mnt/media/Documents 0755 diego media -"
    "d /mnt/media/Obsidian 0755 diego media -"
    "d /mnt/media/Repos 0755 diego media -"
    "d /mnt/media/Archive 0755 diego media -"
    "d /mnt/media/Pictures 0755 diego media -"
    "d /mnt/media/Pictures/Wallpapers 0755 diego media -"
    "d /mnt/media/Pictures/Photos 0755 diego media -"
    "d /mnt/media/Pictures/Screenshots 0755 diego media -"
    # Transmission (only downloads path; no top-level downloads)
    "d /mnt/media/Transmission 0755 diego media -"
    "d /mnt/media/Transmission/Downloads 0755 diego media -"
    "d /mnt/media/Transmission/Watch 0755 diego media -"
    "d /mnt/media/Transmission/Incomplete 0755 diego media -"
    
    # Servarr storage directories
    "d /nix/storage/servarr 0750 diego media -"
    "d /nix/storage/servarr/sonarr 0750 diego media -"
    "d /nix/storage/servarr/radarr 0750 diego media -"
    "d /nix/storage/servarr/lidarr 0750 diego media -"
       "d /nix/storage/servarr/bazarr 0750 diego media -"
       "d /nix/storage/servarr/prowlarr 0750 diego media -"
       "d /nix/storage/lazylibrarian 0750 diego media -"
       "d /nix/storage/calibre/library 0750 diego media -"
       "d /nix/storage/calibre-web 0750 diego media -"
    
    # Transmission config
    "d /nix/storage/transmission 0750 diego media -"
    "d /nix/storage/transmission/config 0750 diego media -"
  ];
  
  # Environment variables for media services
  environment.variables = {
    MEDIA_ROOT = "/mnt/media";
    MOVIES_PATH = "/mnt/media/Movies";
    TV_PATH = "/mnt/media/Tv";
    MUSIC_PATH = "/mnt/media/Music";
    BOOKS_PATH = "/mnt/media/Books";
    AUDIOBOOKS_PATH = "/mnt/media/Audiobooks";
    DOWNLOADS_PATH = "/mnt/media/Transmission/Downloads";
    INCOMING_PATH = "/mnt/media/Incoming";
    DOCUMENTS_PATH = "/mnt/media/Documents";
    OBSIDIAN_PATH = "/mnt/media/Obsidian";
    REPOS_PATH = "/mnt/media/Repos";
    ARCHIVE_PATH = "/mnt/media/Archive";
    PICTURES_PATH = "/mnt/media/Pictures";
  };
}