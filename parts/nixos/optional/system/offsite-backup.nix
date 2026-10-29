{ ... }:
{
  flake.modules.nixos.system-offsite-backup = {
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.backups.restic;

  script = pkgs.writeShellScript "backups-restic.sh" ''
    set -euo pipefail

    PW_DIR=/run/backups-restic
    printf '%s' "$RESTIC_LOCAL_PASSWORD" > "$PW_DIR/local"
    printf '%s' "$RESTIC_REMOTE_PASSWORD" > "$PW_DIR/remote"
    chmod 600 "$PW_DIR/local" "$PW_DIR/remote"
    mkdir -p "$PW_DIR/cache"

    ENDPOINT=''${RESTIC_S3_ENDPOINT:-}
    LOCAL_REPO=$BACKUPS_RESTIC_LOCAL_REPO
    BUCKET=$BACKUPS_RESTIC_REMOTE_BUCKET
    REMOTE_REPO="s3:''${ENDPOINT}/''${BUCKET}"
    RETENTION=(--keep-daily ${toString cfg.retention.keepDaily} --keep-weekly ${toString cfg.retention.keepWeekly} --keep-monthly ${toString cfg.retention.keepMonthly} --prune)

    sources=(${lib.concatStringsSep " " (map (p: lib.escapeShellArg p) cfg.sources)})
    if [ "''${#sources[@]}" -eq 0 ]; then
      echo "backups-restic: no sources configured, nothing to do"
      exit 0
    fi

    valid=()
    for src in "''${sources[@]}"; do
      if [ -d "$src" ] && [ -n "$(find "$src" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
        valid+=("$src")
      else
        echo "backups-restic: skipping missing or empty source: $src"
      fi
    done
    if [ "''${#valid[@]}" -eq 0 ]; then
      echo "backups-restic: no populated sources, nothing to back up"
      exit 0
    fi

    init_repo() {
      local repo=$1
      shift
      if ! restic "$@" -r "$repo" --password-file "$PW_DIR/local" snapshots >/dev/null 2>&1; then
        mkdir -p "$repo"
        restic "$@" -r "$repo" --password-file "$PW_DIR/local" init
      fi
    }

    remote_enabled() {
      [ -n "$ENDPOINT" ] \
        && [ -n "''${AWS_ACCESS_KEY_ID:-}" ] \
        && [[ "$AWS_ACCESS_KEY_ID" != *REPLACE* ]] \
        && [[ "$AWS_SECRET_ACCESS_KEY" != *REPLACE* ]]
    }

    # A run killed by a switch or reboot leaves a lock behind, and every later
    # run then fails with exit 11 ("repository is already locked"). `unlock`
    # without --remove-all only removes stale locks, never a live one.
    init_repo "$LOCAL_REPO"
    restic -r "$LOCAL_REPO" --password-file "$PW_DIR/local" unlock || true
    for src in "''${valid[@]}"; do
      echo "backups-restic: backing up $src"
      restic -r "$LOCAL_REPO" --password-file "$PW_DIR/local" backup "$src"
    done

    echo "backups-restic: pruning local repo"
    restic -r "$LOCAL_REPO" --password-file "$PW_DIR/local" forget "''${RETENTION[@]}"

    if remote_enabled; then
      echo "backups-restic: initializing remote repo if needed"
      if ! restic -r "$REMOTE_REPO" --password-file "$PW_DIR/remote" snapshots >/dev/null 2>&1; then
        restic -r "$REMOTE_REPO" --password-file "$PW_DIR/remote" init
      fi
      restic -r "$REMOTE_REPO" --password-file "$PW_DIR/remote" unlock || true

      echo "backups-restic: copying snapshots to $REMOTE_REPO"
      restic copy \
        --from-repo "$LOCAL_REPO" --from-password-file "$PW_DIR/local" \
        -r "$REMOTE_REPO" --password-file "$PW_DIR/remote"

      echo "backups-restic: pruning remote repo"
      restic -r "$REMOTE_REPO" --password-file "$PW_DIR/remote" forget "''${RETENTION[@]}"
    else
      echo "backups-restic: remote not configured yet (R2 creds pending); local-only run"
    fi

    declare -A extra_repos=(
      ${lib.concatStringsSep "\n      " (
        lib.mapAttrsToList (name: remote: "[${name}]=${lib.escapeShellArg remote.repo}") cfg.extraRemotes
      )}
    )
    for name in "''${!extra_repos[@]}"; do
      repo="''${extra_repos[$name]}"
      upper=$(echo "$name" | tr '[:lower:]' '[:upper:]')
      pwvar="RESTIC_EXTRA_PASSWORD_''${upper}"
      pw="''${!pwvar:-}"
      if [ -z "$pw" ]; then
        echo "backups-restic: skipping extra remote $name, no password set ($pwvar)"
        continue
      fi
      printf '%s' "$pw" > "$PW_DIR/$name"
      chmod 600 "$PW_DIR/$name"

      confvar="RCLONE_CONFIG_''${upper}"
      export RCLONE_CONFIG="''${!confvar:-}"

      echo "backups-restic: initializing extra repo $name if needed"
      if ! restic -r "$repo" --password-file "$PW_DIR/$name" snapshots >/dev/null 2>&1; then
        restic -r "$repo" --password-file "$PW_DIR/$name" init
      fi
      restic -r "$repo" --password-file "$PW_DIR/$name" unlock || true

      echo "backups-restic: copying snapshots to $name ($repo)"
      restic copy \
        --from-repo "$LOCAL_REPO" --from-password-file "$PW_DIR/local" \
        -r "$repo" --password-file "$PW_DIR/$name"

      echo "backups-restic: pruning $name"
      restic -r "$repo" --password-file "$PW_DIR/$name" forget "''${RETENTION[@]}"

      unset RCLONE_CONFIG
    done
  '';
in
{
  options.backups.restic = {
    enable = lib.mkEnableOption "restic offsite backups";

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 23:45";
      description = "Systemd calendar expression for the backup timer.";
    };

    retention = lib.mkOption {
      type = lib.types.submodule {
        options = {
          keepDaily = lib.mkOption {
            type = lib.types.int;
            default = 30;
          };
          keepWeekly = lib.mkOption {
            type = lib.types.int;
            default = 12;
          };
          keepMonthly = lib.mkOption {
            type = lib.types.int;
            default = 6;
          };
        };
      };
      default = { };
    };

    localRepo = lib.mkOption {
      type = lib.types.str;
      default = "/nix/storage/restic";
      description = ''
        Local restic repository. Point this at a different physical disk than
        the sources: the default sits on /nix/storage, so a failure of that
        disk destroys the data and its local backups together. Offsite is the
        only protection against losing the whole machine either way.
      '';
    };

    remote = lib.mkOption {
      type = lib.types.submodule {
        options = {
          bucket = lib.mkOption {
            type = lib.types.str;
            description = "Object store bucket name (must already exist in R2).";
          };
          envFile = lib.mkOption {
            type = lib.types.str;
            description = "Path to a sops-generated env file with RESTIC_LOCAL_PASSWORD, RESTIC_REMOTE_PASSWORD, RESTIC_S3_ENDPOINT, AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.";
          };
        };
      };
    };

    sources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories to back up. Only non-empty directories are snapshotted.";
    };

    extraRemotes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            repo = lib.mkOption {
              type = lib.types.str;
              description = "Restic repository URL, e.g. \"rclone:proton:cobalto-backups\".";
            };
            envFile = lib.mkOption {
              type = lib.types.str;
              description = ''
                sops-generated env file providing RESTIC_EXTRA_PASSWORD_<NAME> (repo
                encryption password) and, for rclone-backed repos,
                RCLONE_CONFIG_<NAME> (path to the rclone config file), where <NAME>
                is the attribute name upper-cased.
              '';
            };
          };
        }
      );
      default = { };
      description = "Additional restic repositories the local repo is copied and pruned to, alongside the primary S3 remote.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.remote.bucket != "";
        message = "backups.restic.remote.bucket must be set";
      }
    ];

    systemd.services.backups-restic = {
      description = "restic backups (local + offsite)";
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
      unitConfig.RequiresMountsFor = [ cfg.localRepo ];
      path = [
        pkgs.restic
        pkgs.bash
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.rclone
      ];

      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = [ cfg.remote.envFile ] ++ (lib.mapAttrsToList (_: remote: remote.envFile) cfg.extraRemotes);
        Environment = [
          "BACKUPS_RESTIC_LOCAL_REPO=${cfg.localRepo}"
          "BACKUPS_RESTIC_REMOTE_BUCKET=${cfg.remote.bucket}"
          "RESTIC_CACHE_DIR=/run/backups-restic/cache"
        ];
        ExecStart = script;
        RuntimeDirectory = "backups-restic";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ReadWritePaths = [ cfg.localRepo ];
        Restart = "on-failure";
        RestartSec = "5m";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        Nice = 10;
      };
    };

    systemd.tmpfiles.settings."10-restic".${cfg.localRepo} = {
      d = {
        user = "root";
        group = "root";
        mode = "0700";
      };
    };

    systemd.timers.backups-restic = {
      description = "Trigger for backups-restic.service";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "10m";
        Unit = "backups-restic.service";
      };
    };
  };
};
}
