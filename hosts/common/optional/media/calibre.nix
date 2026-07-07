{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Calibre Content Server - serves the calibre library via OPDS/API
  # Port 8081
  # Calibre-Web - Web UI for browsing/reading ebooks
  # Port 8083 - nicer web interface
  # Public access enabled - no authentication, all IPs allowed

  # Allow access from all interfaces/IPs
  networking.firewall.allowedTCPPorts = [
    8081
    8083
  ];

  # Calibre Content Server
  services.calibre-server = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
    host = "0.0.0.0";
    port = 8081;
    libraries = [ "/nix/storage/calibre/library" ];
    auth.enable = false; # Public access - no authentication required
  };

  # Calibre-Web - Web UI for browsing/reading ebooks
  services.calibre-web = {
    enable = true;
    user = "diego";
    group = "media";
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    dataDir = "/nix/storage/calibre-web";
    calibrePackage = pkgs.calibre;
    options = {
      calibreLibrary = "/nix/storage/calibre/library";
      enableBookConversion = true;
      enableBookUploading = true;
    };
  };

  # Ensure media group exists
  users.groups.media = { };

  # Initialize calibre library if it doesn't exist
  systemd.services.calibre-init = {
    description = "Initialize Calibre library";
    wantedBy = [ "multi-user.target" ];
    before = [
      "calibre-server.service"
      "calibre-web.service"
    ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /nix/storage/calibre/library
      chown diego:media /nix/storage/calibre/library
      chmod 750 /nix/storage/calibre/library
      if [ ! -f /nix/storage/calibre/library/metadata.db ]; then
        echo "[calibre-init] Initializing calibre library..."
        ${pkgs.calibre}/bin/calibredb --library-path /nix/storage/calibre/library list
        chown -R diego:media /nix/storage/calibre/library
      fi
    '';
  };

  # Configure calibre-web for public access (no authentication required)
  systemd.services.calibre-web-public = {
    description = "Configure Calibre-Web for public access";
    wantedBy = [ "multi-user.target" ];
    after = [ "calibre-web.service" ];
    requires = [ "calibre-web.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "diego";
      Group = "media";
    };
    path = [ pkgs.sqlite ];
    script = ''
      DB="/nix/storage/calibre-web/app.db"

      # Wait for database to exist
      for i in $(seq 1 15); do
        if [ -f "$DB" ]; then
          break
        fi
        sleep 2
      done

      if [ ! -f "$DB" ]; then
        echo "[calibre-web-public] Database not found, skipping"
        exit 0
      fi

      echo "[calibre-web-public] Enabling public access (anonymous browsing)..."

      # Enable anonymous browsing in settings (config_anonbrowse = 1)
      sqlite3 "$DB" "UPDATE settings SET config_anonbrowse = 1, config_calibre_dir = '/nix/storage/calibre/library' WHERE id = 1;"

      echo "[calibre-web-public] Public access enabled - no login required"
    '';
  };

  # Systemd tmpfiles for calibre directories
  systemd.tmpfiles.rules = [
    "d /nix/storage/calibre 0750 diego media -"
    "d /nix/storage/calibre/library 0750 diego media -"
    "d /nix/storage/calibre-web 0750 diego media -"
  ];
}
