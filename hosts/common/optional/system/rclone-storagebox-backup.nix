{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.rclone-storagebox-backup;
in
{
  options.services.rclone-storagebox-backup = with lib; {
    enable = mkEnableOption "rclone backup to Hetzner Storage Box";
    remotePath = mkOption {
      type = types.str;
      default = "/backup";
      description = "Path on Storage Box to sync to";
    };
    syncPaths = mkOption {
      type = types.listOf types.str;
      default = [ "/var/lib/data" ];
      description = "Paths to sync to Storage Box";
    };
    schedule = mkOption {
      type = types.str;
      default = "04:00";
      description = "Daily schedule time";
    };
  };

  config = lib.mkIf config.services.rclone-storagebox-backup.enable {
    environment.systemPackages = [ pkgs.rclone ];

    # Declare sops secrets for rclone storagebox credentials
    sops.secrets."rclone-storagebox-user" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    sops.secrets."rclone-storagebox-pass" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    systemd.services.rclone-storagebox-backup = {
      description = "Sync data to Hetzner Storage Box via rclone";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        StandardOutput = "journal";
        StandardError = "journal";
        PrivateTmp = true;
      };
      script = ''
                set -e

                CONFIG_DIR=$(mktemp -d)
                trap "rm -rf $CONFIG_DIR" EXIT

                cat > "$CONFIG_DIR/rclone.conf" << EOF
        [storagebox]
        type = sftp
        host = u575032.your-storagebox.de
        user = ${config.sops.secrets.rclone-storagebox-user.path}
        pass = ${config.sops.secrets.rclone-storagebox-pass.path}
        key_file = 
        EOF

                for path in ${lib.concatStringsSep " " cfg.syncPaths}; do
                  if [ -e "$path" ]; then
                    echo "Syncing $path to storagebox:${cfg.remotePath}$(basename $path)"
                    rclone sync "$path" "storagebox:${cfg.remotePath}$(basename $path)" \
                      --config "$CONFIG_DIR/rclone.conf" \
                      --delete-during \
                      --transfers 4 \
                      --checkers 8 \
                      -v
                  fi
                done
      '';
    };

    systemd.timers.rclone-storagebox-backup = {
      description = "Daily Storage Box backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        Unit = "rclone-storagebox-backup.service";
      };
    };
  };
}
