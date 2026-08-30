{ config, lib, pkgs, ... }:

{

  virtualisation.docker.enable = true;

  users.users.diego.extraGroups = [ "docker" ];

  networking.firewall.interfaces."enp6s0" = {
    allowedTCPPorts = [
      9091
      6881
    ];
    allowedUDPPorts = [
      6881
    ];
  };

  systemd.services.qbittorrent = {
    description = "qBittorrent with VueTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "qbittorrent-setup.service" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "start-qbittorrent" ''
        ${pkgs.docker}/bin/docker stop qbittorrent-cobalto 2>/dev/null || true
        ${pkgs.docker}/bin/docker rm qbittorrent-cobalto 2>/dev/null || true

        ${pkgs.docker}/bin/docker run -d \
          --name qbittorrent-cobalto \
          --restart unless-stopped \
          -p 9091:8080 \
          -p 6881:6881 \
          -p 6881:6881/udp \
          -e PUID=1000 \
          -e PGID=1000 \
          -e TZ=America/Santiago \
          -e WEBUI_PORT=8080 \
          -v /var/lib/qbittorrent:/config \
          -v /mnt/media/Transmission/Downloads:/downloads \
          -v /mnt/media/Transmission/Incomplete:/incomplete \
          -v /mnt/media/Transmission/Watch:/watch \
          lscr.io/linuxserver/qbittorrent:latest

        echo "qBittorrent container started with VueTorrent UI"
        echo "Access at: http://cobalto.minerales.network:9091"
        echo "Default credentials: admin / adminadmin (change on first login)"
      '';

      ExecStop = pkgs.writeShellScript "stop-qbittorrent" ''
        ${pkgs.docker}/bin/docker stop qbittorrent-cobalto || true
        ${pkgs.docker}/bin/docker rm qbittorrent-cobalto || true
      '';
    };
  };

  users.groups.media = {};

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

      mkdir -p /mnt/media/Transmission/{Downloads/complete,Incomplete,Watch}

      mkdir -p /mnt/media/Transmission/Downloads/complete/{radarr,sonarr,lidarr,lazylibrarian,bazarr}
      mkdir -p /mnt/media/Transmission/Incomplete/{radarr,sonarr,lidarr,lazylibrarian,bazarr}

      mkdir -p /var/lib/qbittorrent

      chown -R diego:media /mnt/media/Transmission
      chown -R diego:media /var/lib/qbittorrent
      chmod -R 755 /mnt/media/Transmission
      chmod -R 755 /var/lib/qbittorrent

      echo "[qbittorrent] Directories ready:"
      echo "  - Downloads: /mnt/media/Transmission/Downloads/complete/"
      echo "  - Incomplete: /mnt/media/Transmission/Incomplete/"
      echo "  - Watch: /mnt/media/Transmission/Watch/"
      echo "  - Config: /var/lib/qbittorrent"
      echo "  - Categories: radarr, sonarr, lidarr, lazylibrarian, bazarr"
    '';
  };
}
