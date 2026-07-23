{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.invidious;
  defaultUser = "diego";
  invidiousPassword = "5jjugQJQzqTuTHEMmTs5Zy7U1R585XBD";
  companionSecret = "p2UX7EBHxazhKqNM"; # 16 chars
  yatteeContainer = "yattee-server";
  yatteeService = "podman-${yatteeContainer}";
  yatteePort = 8085;

  syncSubscriptionsScript = pkgs.writeShellScript "sync-invidious-to-yattee" ''
    set -euo pipefail

    SUBS=$(${pkgs.su}/bin/su -s /bin/sh postgres -c "${pkgs.postgresql_16}/bin/psql -d invidious -t -A -c \"SELECT unnest(subscriptions) FROM users WHERE email = '${defaultUser}';\"")

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
    HOST="http://127.0.0.1:${toString cfg.port}"

    ${pkgs.curl}/bin/curl -sf -o /dev/null \
      --retry 30 --retry-delay 2 --retry-connrefused \
      "$HOST/api/v1/stats" || exit 1

    HASH=$(${pkgs.python3.withPackages (ps: [ ps.bcrypt ])}/bin/python3 -c "
import bcrypt, sys
sys.stdout.write(bcrypt.hashpw(sys.argv[1].encode(), bcrypt.gensalt(rounds=12)).decode())
" "${invidiousPassword}")

    ${pkgs.su}/bin/su -s /bin/sh postgres -c "${pkgs.postgresql_16}/bin/psql -d invidious -c \
      \"INSERT INTO users (email, password, preferences)
       VALUES ('${defaultUser}', '$HASH', '{}')
       ON CONFLICT (email) DO UPDATE SET password = '$HASH';\""
    echo "Invidious admin user created/verified"
  '';
in
{
  services.invidious = {
    enable = true;
    port = 3000;
    address = "0.0.0.0";
    domain = "invidious.minerales.network";

    database.createLocally = true;

    settings = {
      db = {
        user = "invidious";
        dbname = "invidious";
      };
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
      default_user_preferences = {};
    };
  };

  # One-shot migration: copy PostgreSQL data from podman volume to native PostgreSQL
  # This runs before postgresql starts. Safe to re-run (idempotent).
  systemd.services.invidious-pg-migration = {
    description = "Migrate Invidious PostgreSQL data from podman to native";
    before = [ "postgresql.target" ];
    wantedBy = [ "postgresql.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = let
      pgDataDir = config.services.postgresql.dataDir;
    in ''
      set -euo pipefail

      # If native data dir already has a PG_VERSION, migration already done
      if [ -f "${pgDataDir}/PG_VERSION" ]; then
        echo "invidious-pg-migration: already migrated, skipping"
        exit 0
      fi

      # Find the podman volume mount point for invidious-pgdata
      VOLUME_MP=$(${pkgs.podman}/bin/podman volume inspect invidious-pgdata --format '{{.Mountpoint}}' 2>/dev/null || echo "")
      if [ -z "$VOLUME_MP" ]; then
        echo "invidious-pg-migration: no podman volume invidious-pgdata found, starting fresh"
        exit 0
      fi

      if [ ! -f "$VOLUME_MP/PG_VERSION" ]; then
        echo "invidious-pg-migration: podman volume has no PG_VERSION, starting fresh"
        exit 0
      fi

      echo "invidious-pg-migration: copying data from $VOLUME_MP to ${pgDataDir}"
      mkdir -p "${pgDataDir}"
      ${pkgs.rsync}/bin/rsync -a --delete "$VOLUME_MP/" "${pgDataDir}/"
      chown -R postgres:postgres "${pgDataDir}"
      echo "invidious-pg-migration: done"
    '';
  };

  # Native companion service — replaces the podman container
  systemd.services.invidious-companion = {
    description = "Invidious Companion (YouTube video stream handler)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "invidious-companion";
      Environment = [
        "SERVER_SECRET_KEY=${companionSecret}"
        "HOST=127.0.0.1"
        "PORT=8282"
        "SERVER_BASE_PATH=/companion"
        "CACHE_DIRECTORY=/var/lib/invidious-companion"
      ];
      ExecStart = "${pkgs.invidious-companion}/bin/invidious-companion";
      Restart = "always";
      RestartSec = 2;
      StartLimitBurst = 10;
      # Security hardening (from upstream systemd unit)
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      SystemCallArchitectures = "native";
      ReadWritePaths = [ "/var/lib/invidious-companion" ];
    };
  };

  # Clear any stale netavark nftables DNAT rule for port 8282 left over from
  # the old podman companion container (which mapped 127.0.0.1:8282 -> a
  # container IP 10.88.0.x). If present, it hijacks loopback traffic to the
  # now-dead container and Invidious gets "No route to host". Runs as root
  # after the companion starts.
  systemd.services.invidious-companion-dnat-cleanup = {
    description = "Clear stale netavark DNAT rule for Invidious companion port 8282";
    after = [ "invidious-companion.service" "podman-${yatteeContainer}.service" ];
    wants = [ "invidious-companion.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -u
      NFT=${pkgs.nftables}/bin/nft
      CT=${pkgs.conntrack-tools}/bin/conntrack
      if $NFT list chain inet netavark nv_00000000_10_88_0_0_nm16_dnat 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "dport 8282"; then
        echo "[companion-dnat-cleanup] flushing stale 8282 DNAT chain"
        $NFT flush chain inet netavark nv_00000000_10_88_0_0_nm16_dnat 2>/dev/null || true
        $CT -F 2>/dev/null || true
      else
        echo "[companion-dnat-cleanup] no stale 8282 DNAT rule"
      fi
    '';
  };

  systemd.services.invidious-create-user = {
    description = "Create default Invidious user";
    after = [ "invidious.service" ];
    wants = [ "invidious.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = createUserScript;
      RemainAfterExit = true;
    };
  };

  # Yattee server — kept as podman container (no native alternative)
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
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

  systemd.services.invidious-sync-subscriptions = {
    description = "Sync Invidious subscriptions to Yattee Server";
    after = [ "${yatteeService}.service" ];
    wants = [ "${yatteeService}.service" ];
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
