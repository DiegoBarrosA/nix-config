{ config, lib, pkgs, ... }:

{
  # qBittorrent with VueTorrent Web UI - Modern BitTorrent client
  # Fully compatible with Servarr services and provides beautiful web interface
  
  # Enable Docker for qBittorrent container
  virtualisation.docker.enable = true;
  
  # Add diego to docker group
  users.users.diego.extraGroups = [ "docker" ];
  
  # Firewall configuration  
  networking.firewall.interfaces."enp6s0" = {
    allowedTCPPorts = [
      9091   # qBittorrent Web UI
      6881   # qBittorrent peer port
    ];
    allowedUDPPorts = [
      6881   # qBittorrent DHT
    ];
  };
  
  # Systemd service to run qBittorrent container with VueTorrent UI
  systemd.services.qbittorrent = {
    description = "qBittorrent with VueTorrent Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "qbittorrent-setup.service" ];
    requires = [ "docker.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "start-qbittorrent" ''
        # Stop and remove existing container
        ${pkgs.docker}/bin/docker stop qbittorrent-cobalto 2>/dev/null || true
        ${pkgs.docker}/bin/docker rm qbittorrent-cobalto 2>/dev/null || true
        
        # Start qBittorrent container with VueTorrent UI
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
  
  # Ensure media group exists
  users.groups.media = {};
  
  # Create qBittorrent directories with category subdirectories  
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
      
      # Create base download directories (keep transmission path for compatibility)
      mkdir -p /mnt/media/Transmission/{Downloads/complete,Incomplete,Watch}
      
      # Create category subdirectories for each Servarr service
      mkdir -p /mnt/media/Transmission/Downloads/complete/{radarr,sonarr,lidarr,lazylibrarian,bazarr}
      mkdir -p /mnt/media/Transmission/Incomplete/{radarr,sonarr,lidarr,lazylibrarian,bazarr}
      
      # Create qBittorrent config directory
      mkdir -p /var/lib/qbittorrent
      
      # Set correct ownership and permissions
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
