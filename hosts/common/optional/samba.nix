{ config, lib, pkgs, ... }:

{
  # Samba server configuration for media sharing
  # Provides SMB/CIFS access to media library for Windows/Mac clients
  
  services.samba = {
    enable = true;
    
    # Global configuration
    settings = {
      global = {
        # Server identification
        netbios-name = "cobalto";
        workgroup = "MINERALES";
        description = "Cobalto Media Server";
        
        # Security configuration
        security = "user";
        "map to guest" = "bad user";
        "guest account" = "nobody";
        
        # Performance tuning
        "max connections" = 200;
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        "read raw" = "yes";
        "write raw" = "yes";
        
        # Logging
        "log level" = 1;
        "log file" = "/var/log/samba/%m.log";
        "max log size" = 50000;
        
        # Notification of file changes
        "vfs objects" = "fruit";
        "fruit:encoding" = "native";
        
        # DNS
        "dns proxy" = false;
      };
      
      # Media share - unified media directory access
      media = {
        path = "/mnt/media";
        comment = "Unified Media Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
        "map acl inherit" = "yes";
        "store dos attributes" = "yes";
      };
      
      # Movies share
      movies = {
        path = "/mnt/media/Movies";
        comment = "Movie Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      
      # TV Shows share
      tv = {
        path = "/mnt/media/Tv";
        comment = "TV Show Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      
      # Music share
      music = {
        path = "/mnt/media/Music";
        comment = "Music Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      
      # Books share
      books = {
        path = "/mnt/media/Books";
        comment = "Book Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      
      # Sync shares (Syncthing-backed)
      documents = {
        path = "/mnt/media/Documents";
        comment = "Documents (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      obsidian = {
        path = "/mnt/media/Obsidian";
        comment = "Obsidian vault (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      repos = {
        path = "/mnt/media/Repos";
        comment = "Repositories (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      archive = {
        path = "/mnt/media/Archive";
        comment = "Archive / misc (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      pictures = {
        path = "/mnt/media/Pictures";
        comment = "Pictures (Syncthing: Wallpapers, Photos, Screenshots)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      
      # Storage share (for technical users)
      storage = {
        path = "/nix/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "force user" = "diego";
        "force group" = "users";
        "create mask" = "0755";
        "directory mask" = "0755";
      };
      
      # Downloads share - transmission downloads
      downloads = {
        path = "/mnt/media/Transmission/Downloads";
        comment = "Transmission Downloads";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      
      # Incoming share - for manual media additions
      incoming = {
        path = "/mnt/media/Incoming";
        comment = "Incoming Media (for manual imports)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "diego";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
    };
  };
  
  # Samba client support
  environment.systemPackages = with pkgs; [
    samba
    cifs-utils
  ];
  
  # Firewall configuration for Samba
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      139   # NetBIOS session service
      445   # SMB over TCP
    ];
    allowedUDPPorts = [
      137   # NetBIOS name service
      138   # NetBIOS datagram service
    ];
  };
  
  # Ensure samba service starts on boot
  systemd.services.samba-smbd.enable = true;
  systemd.services.samba-nmbd.enable = true;
}
