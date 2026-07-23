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
        { private_url = "http://192.168.1.85:8282/companion"; }
      ];
      invidious_companion_key = companionSecret;
      default_user_preferences = {};
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
      extraOptions = [ "--network=host" ];
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
      extraOptions = [ "--add-host=host.containers.internal:host-gateway" ];
      environment = {
        HOST = "0.0.0.0";
        PORT = toString yatteePort;
        CORS_ALLOW_ALL = "true";
        INVIDIOUS_INSTANCE_URL = "http://host.containers.internal:3000";
        ADMIN_USERNAME = "diego";
        ADMIN_PASSWORD = invidiousPassword;
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

  systemd.services.${companionService} = {
    serviceConfig.Restart = mkForce "always";
    serviceConfig.StartLimitBurst = 10;
  };

  systemd.services.${yatteeService} = {
    serviceConfig.Restart = mkForce "always";
    postStart = let
      cleanupScript = pkgs.writeShellScript "clean-stale-netavark-rules" ''
        set -u
        echo "[yattee-iptables-cleanup] Running postStart cleanup..."
        CURRENT_ID=$(${pkgs.podman}/bin/podman inspect ${yatteeContainer} --format '{{.Id}}' 2>/dev/null || echo "")
        if [ -z "$CURRENT_ID" ]; then
          echo "[yattee-iptables-cleanup] No running container found, skipping."
          exit 0
        fi
        echo "[yattee-iptables-cleanup] Current container ID: $CURRENT_ID"
        # 1) Remove stale HOSTPORT-DNAT entries (all except current container)
        STALE_HOSTPORT=$(${pkgs.iptables}/bin/iptables -t nat -S NETAVARK-HOSTPORT-DNAT 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep 'tcp .*--dport ${toString yatteePort}' \
          | ${pkgs.gnugrep}/bin/grep -v "$CURRENT_ID" || true)
        if [ -n "$STALE_HOSTPORT" ]; then
          echo "$STALE_HOSTPORT" | ${pkgs.gnused}/bin/sed 's|^-A |${pkgs.iptables}/bin/iptables -t nat -D |' \
            | while IFS= read -r cmd; do
                echo "[yattee-iptables-cleanup] Executing: $cmd"
                eval "$cmd" || echo "[yattee-iptables-cleanup] eval failed (exit $?)"
              done
        else
          echo "[yattee-iptables-cleanup] No stale HOSTPORT-DNAT entries."
        fi
        echo "[yattee-iptables-cleanup] Done."
      '';
    in ''
      sleep 2
      ${cleanupScript}
    '';
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

  systemd.services.invidious = let
    writableConfigFile = "/var/lib/invidious/config/config.yml";
    settingsFile = (pkgs.formats.json {}).generate "invidious-settings" cfg.settings;
  in {
    after = mkAfter [ "${companionService}.service" ];
    wants = [ "${companionService}.service" ];

    serviceConfig.StateDirectory = "invidious";
    serviceConfig.StateDirectoryMode = "0750";
    serviceConfig.WorkingDirectory = "/var/lib/invidious";

    script = lib.mkForce ''
      # Generate hmac_key if missing
      HMAC_KEY_FILE="/var/lib/invidious/hmac_key"
      if [ ! -e "$HMAC_KEY_FILE" ]; then
        ${pkgs.pwgen}/bin/pwgen 20 1 > "$HMAC_KEY_FILE"
        chmod 0600 "$HMAC_KEY_FILE"
      fi

      # Merge config parts into YAML
      mkdir -p /var/lib/invidious/config
      configParts=()
      configParts+=("$(${pkgs.jq}/bin/jq -R '{"hmac_key":.}' <"$HMAC_KEY_FILE")")
      configParts+=("$(< ${settingsFile})")
      configParts+=('{"port":${toString cfg.port}}')

      mergedConfig="$(${pkgs.jq}/bin/jq -s 'reduce .[] as $item ({}; . * $item)' <<<"''${configParts[*]}")"
      echo "$mergedConfig" | ${pkgs.yq-go}/bin/yq -P > "${writableConfigFile}"
      chmod 0640 "${writableConfigFile}"

      export INVIDIOUS_CONFIG_FILE="${writableConfigFile}"
      exec ${cfg.package}/bin/invidious
    '';
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
