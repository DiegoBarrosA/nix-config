{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.invidious;
  defaultUser = "diego";
  invidiousPassword = "5jjugQJQzqTuTHEMmTs5Zy7U1R585XBD";
  passwordFile = "/run/invidious/password";
  pgContainer = "invidious-postgres";
  pgService = "podman-${pgContainer}";
  companionContainer = "invidious-companion";
  companionService = "podman-${companionContainer}";
  companionSecret = "p2UX7EBHxazhKqNM"; # 16 chars
  yatteeContainer = "yattee-server";
  yatteeService = "podman-${yatteeContainer}";
  yatteePort = 8085;
  invidiousUser = "diego";

  syncSubscriptionsScript = pkgs.writeShellScript "sync-invidious-to-yattee" ''
    set -euo pipefail

    SUBS=$(PGPASSWORD=invidious ${pkgs.postgresql_16}/bin/psql -h localhost -p 5433 -U invidious -d invidious -t -A \
      -c "SELECT unnest(subscriptions) FROM users WHERE email = '${invidiousUser}';")

    YATTEE_DATA=$(${pkgs.podman}/bin/podman volume inspect yattee-data --format '{{.Mountpoint}}' 2>/dev/null || echo "")
    if [ -z "$YATTEE_DATA" ]; then
      echo "Error: yattee-data volume not found"
      exit 1
    fi

    DB="$YATTEE_DATA/yattee.db"
    if [ ! -f "$DB" ]; then
      echo "Error: Yattee database not found at $DB"
      exit 1
    fi

    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ADDED=0
    for UCID in $SUBS; do
      [ -z "$UCID" ] && continue
      ${pkgs.sqlite}/bin/sqlite3 "$DB" \
        "INSERT OR IGNORE INTO watched_channels (channel_id, site, last_requested)
         VALUES ('$UCID', 'youtube', '$NOW');"
      ADDED=$((ADDED + 1))
    done

    ${pkgs.sqlite}/bin/sqlite3 "$DB" \
      "UPDATE watched_channels SET last_requested = '$NOW' WHERE site = 'youtube';"

    echo "Synced $ADDED subscriptions from Invidious to Yattee"
  '';

  createUserScript = pkgs.writeShellScript "invidious-create-user" ''
    set -e
    PASSWORD="$(cat ${passwordFile})"
    HOST="http://127.0.0.1:${toString cfg.port}"

    ${pkgs.curl}/bin/curl -sf -o /dev/null \
      --retry 30 --retry-delay 2 --retry-connrefused \
      "$HOST/api/v1/stats" || exit 1

    HASH=$(${pkgs.python3.withPackages (ps: [ ps.bcrypt ])}/bin/python3 -c "
import bcrypt, sys
sys.stdout.write(bcrypt.hashpw(sys.argv[1].encode(), bcrypt.gensalt(rounds=12)).decode())
" "$PASSWORD")

    cat > /tmp/invidious-create-user.sql <<PSQLSTOP
INSERT INTO users (email, password, preferences)
VALUES ('${defaultUser}@localhost', :'hash', '{}')
ON CONFLICT (email) DO UPDATE SET password = :'hash';
PSQLSTOP
    PGPASSWORD=invidious ${pkgs.postgresql_16}/bin/psql -h localhost -p 5433 -U invidious -d invidious \
      -v hash="$HASH" -f /tmp/invidious-create-user.sql
    rm -f /tmp/invidious-create-user.sql
    echo "Invidious admin user created/verified"
  '';
in
{
  services.invidious = {
    enable = true;
    port = 3000;
    settings = {
      host_binding = mkForce "0.0.0.0";
      domain = "invidious.minerales.network";
      external_port = 443;
      https_only = true;
      registration_enabled = true;
      login_enabled = true;
      captcha_enabled = false;
      statistics_enabled = true;
      admins = [ defaultUser ];
      invidious_companion = [
        { private_url = "http://127.0.0.1:8282/companion"; }
      ];
      invidious_companion_key = companionSecret;
      db = mkForce {
        user = "invidious";
        password = "invidious";
        host = "localhost";
        port = 5433;
        dbname = "invidious";
      };
    };
  };

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.${pgContainer} = {
      image = "docker.io/postgres:16-alpine";
      autoStart = true;
      ports = [ "127.0.0.1:5433:5432" ];
      environment = {
        POSTGRES_DB = "invidious";
        POSTGRES_USER = "invidious";
        POSTGRES_PASSWORD = "invidious";
      };
      volumes = [
        "invidious-pgdata:/var/lib/postgresql/data:rw"
      ];
    };
    containers.${companionContainer} = {
      image = "quay.io/invidious/invidious-companion:latest";
      autoStart = true;
      ports = [ "127.0.0.1:8282:8282" ];
      environment = {
        SERVER_SECRET_KEY = companionSecret;
      };
      volumes = [
        "invidious-companion-cache:/var/tmp/youtubei.js:rw"
      ];
    };
    containers.${yatteeContainer} = {
      image = "docker.io/yattee/yattee-server:latest";
      autoStart = true;
      ports = [ "127.0.0.1:${toString yatteePort}:${toString yatteePort}" ];
      environment = {
        HOST = "0.0.0.0";
        PORT = toString yatteePort;
        CORS_ALLOW_ALL = "true";
        INVIDIOUS_INSTANCE = "http://127.0.0.1:3000";
      };
      volumes = [
        "yattee-downloads:/downloads:rw"
        "yattee-data:/app/data:rw"
      ];
    };
  };

  systemd.services.${pgService} = {
    serviceConfig.Restart = mkForce "always";
  };

  systemd.services.${yatteeService} = {
    serviceConfig.Restart = mkForce "always";
  };

  systemd.tmpfiles.rules = [
    "d /run/invidious 0750 invidious invidious -"
  ];

  systemd.services.invidious-write-password = {
    description = "Write Invidious admin password";
    after = [ "systemd-tmpfiles-setup.service" ];
    before = [ "invidious-create-user.service" ];
    wantedBy = [ "invidious-create-user.service" ];
    requiredBy = [ "invidious-create-user.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /run/invidious
      install -m 0400 -o invidious -g invidious \
        ${pkgs.writeText "invidious-password" invidiousPassword} ${passwordFile}
    '';
  };

  systemd.services.invidious = {
    after = mkAfter [ "${companionService}.service" ];
    wants = [ "${companionService}.service" ];
  };

  systemd.services.invidious-create-user = {
    description = "Create default Invidious user";
    after = [ "invidious.service" "${pgService}.service" "${companionService}.service" "invidious-write-password.service" ];
    wants = [ "invidious.service" "${pgService}.service" "${companionService}.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = createUserScript;
      User = "invidious";
      Group = "invidious";
      RemainAfterExit = true;
    };
  };

  systemd.services.invidious-sync-subscriptions = {
    description = "Sync Invidious subscriptions to Yattee Server";
    after = [ "${yatteeService}.service" "${pgService}.service" ];
    wants = [ "${yatteeService}.service" "${pgService}.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = syncSubscriptionsScript;
      RemainAfterExit = true;
    };
  };

  systemd.timers.invidious-sync-subscriptions = {
    description = "Periodic sync of Invidious subscriptions to Yattee Server";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 3000 yatteePort ];
}
