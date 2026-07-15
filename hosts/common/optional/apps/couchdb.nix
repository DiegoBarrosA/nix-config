{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.couchdb;
  adminIniPath = "/run/couchdb/admin.ini";

  initScript = pkgs.writeShellScript "couchdb-livesync-init" ''
    set -e
    HOSTNAME="http://127.0.0.1:${toString cfg.port}"
    USERNAME="$(cat ${config.sops.secrets."couchdb-admin-user".path})"
    PASSWORD="$(cat ${config.sops.secrets."couchdb-admin-password".path})"

    echo "-- Configuring CouchDB for Obsidian LiveSync..."
    ${pkgs.curl}/bin/curl -sf -X POST "$HOSTNAME/_cluster_setup" \
      -H "Content-Type: application/json" \
      -d "{\"action\":\"enable_single_node\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"bind_address\":\"0.0.0.0\",\"port\":${toString cfg.port},\"singlenode\":true}" \
      --user "$USERNAME:$PASSWORD" || echo "cluster_setup skipped (already configured)"
    echo "-- CouchDB LiveSync init done"
  '';

  # Script to write admin credentials as CouchDB ini file at runtime
  prepareAdminScript = pkgs.writeShellScript "couchdb-prepare-admin" ''
    set -e
    mkdir -p /run/couchdb
    USER="$(cat ${config.sops.secrets."couchdb-admin-user".path})"
    PASS="$(cat ${config.sops.secrets."couchdb-admin-password".path})"
    cat > ${adminIniPath} << INI
[admins]
$USER = $PASS
INI
    chown couchdb:couchdb ${adminIniPath}
    chmod 640 ${adminIniPath}
  '';
in
{
  services.couchdb = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = 5984;
    adminUser = "";
    adminPass = null;
    # Runtime-generated admin credentials file
    extraConfigFiles = [ adminIniPath ];
    extraConfig = {
      chttpd = {
        require_valid_user = "true";
        enable_cors = "true";
        max_http_request_size = "4294967296";
      };
      chttpd_auth = {
        require_valid_user = "true";
      };
      httpd = {
        WWW-Authenticate = ''Basic realm="couchdb"'';
        enable_cors = "true";
      };
      couchdb = {
        max_document_size = "50000000";
      };
      cors = {
        credentials = "true";
        origins = "app://obsidian.md,capacitor://localhost,http://localhost";
      };
    };
  };

  sops.secrets = {
    "couchdb-admin-user" = {
      owner = "couchdb";
      group = "couchdb";
      mode = "0400";
    };
    "couchdb-admin-password" = {
      owner = "couchdb";
      group = "couchdb";
      mode = "0400";
    };
  };

  # Write admin credentials into /run/couchdb/admin.ini before couchdb starts
  # Runs as couchdb user so the ini file is owned correctly for couchdb to read
  systemd.services.couchdb-prepare-admin = {
    description = "Prepare CouchDB admin credentials from SOPS secrets";
    before = [ "couchdb.service" ];
    wantedBy = [ "couchdb.service" ];
    requiredBy = [ "couchdb.service" ];
    wants = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = prepareAdminScript;
      RemainAfterExit = true;
    };
  };

  # One-shot init after couchdb is running (cluster setup, first-time CouchDB init)
  systemd.services.couchdb-livesync-init = {
    description = "Initialize CouchDB for Obsidian LiveSync";
    after = [ "couchdb.service" ];
    wants = [ "couchdb.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = initScript;
      User = "couchdb";
      Group = "couchdb";
      RemainAfterExit = true;
    };
  };

  # Clean up admin ini on stop
  systemd.tmpfiles.rules = [
    "d /run/couchdb 0750 couchdb couchdb -"
  ];

  networking.firewall.allowedTCPPorts = [ 5984 ];
}
