{ config, lib, pkgs, ... }:

{

  services.samba = {
    enable = true;

    settings = {
      global = {

        netbios-name = "cobalto";
        workgroup = "MINERALES";
        description = "Cobalto Media Server";

        security = "user";
        "map to guest" = "bad user";
        "guest account" = "nobody";

        "max connections" = 200;
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        "read raw" = "yes";
        "write raw" = "yes";

        "log level" = 1;
        "log file" = "/var/log/samba/%m.log";
        "max log size" = 50000;

        "vfs objects" = "fruit";
        "fruit:encoding" = "native";

        "dns proxy" = false;
      };

      media = {
        path = "/srv/media";
        comment = "Unified Media Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
        "map acl inherit" = "yes";
        "store dos attributes" = "yes";
      };

      library = {
        path = "/srv/media/library";
        comment = "Media Library (Movies, Series, Music, Books)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };

      tv = {
        path = "/srv/media/library/series";
        comment = "TV Show Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };

      music = {
        path = "/srv/media/library/music";
        comment = "Music Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };

      books = {
        path = "/srv/media/library/books";
        comment = "Book Library";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };

      documents = {
        path = "/srv/media/Documents";
        comment = "Documents (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      obsidian = {
        path = "/srv/media/Obsidian";
        comment = "Obsidian vault (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      repos = {
        path = "/srv/media/Repos";
        comment = "Repositories (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      archive = {
        path = "/srv/media/Archive";
        comment = "Archive / misc (Syncthing)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
      pictures = {
        path = "/srv/media/Pictures";
        comment = "Pictures (Syncthing: Wallpapers, Photos, Screenshots)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };

      storage = {
        path = "/nix/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
      };

      downloads = {
        path = "/srv/media/downloads";
        comment = "Downloads (qBittorrent)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };

      incoming = {
        path = "/srv/media/Incoming";
        comment = "Incoming Media (for manual imports)";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0755";
        "directory mask" = "0755";
        "vfs objects" = "fruit acl_xattr";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    samba
    cifs-utils
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      139
      445
    ];
    allowedUDPPorts = [
      137
      138
    ];
  };

  systemd.services.samba-smbd.enable = true;
  systemd.services.samba-nmbd.enable = true;
}
