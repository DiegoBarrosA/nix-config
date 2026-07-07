# Backup /mnt/media to Proton Drive via rclone (excludes Movies, Tv, Transmission, Incoming).
# Place your rclone remote config at configPath (e.g. from another PC: scp ~/.config/rclone/rclone.conf cobalto:/nix/persist/etc/rclone-proton.conf).
# Optional: use SOPS by adding sops.secrets and copying the decrypted file to configPath in an activation script.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.proton-drive-backup;
in
{
  options.services.proton-drive-backup = with lib; {
    configPath = mkOption {
      type = types.str;
      default = "/nix/persist/etc/rclone-proton.conf";
      description = "Path to rclone config file containing the Proton Drive remote (e.g. [proton] type = protondrive ...).";
    };
    remoteName = mkOption {
      type = types.str;
      default = "proton";
      description = "Name of the rclone remote in the config file (e.g. [proton] or [protondrive]).";
    };
    destinationPath = mkOption {
      type = types.str;
      default = "";
      description = "Path on Proton Drive to sync to; empty string = root of the drive.";
    };
  };

  config = {
    systemd.services.proton-drive-backup = {
      description = "Sync /mnt/media to Proton Drive (rclone)";
      after = [ "network-online.target" "mnt-media.mount" ];
      wants = [ "network-online.target" "mnt-media.mount" ];
      serviceConfig = {
        Type = "oneshot";
        User = "diego";
        Group = "media";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      path = [ pkgs.rclone ];
      script = ''
        set -e
        if [ ! -f ${cfg.configPath} ]; then
          echo "proton-drive-backup: Missing rclone config at ${cfg.configPath}. Create it (e.g. copy from another PC) to enable backup."
          exit 1
        fi
        exec rclone sync /mnt/media ${cfg.remoteName}:${cfg.destinationPath} \
          --config ${cfg.configPath} \
          --exclude "Movies/**" \
          --exclude "Tv/**" \
          --exclude "Transmission/**" \
          --exclude "Incoming/**" \
          -v
      '';
    };

    # Ensure rclone config is readable by diego (service user); applied when file exists
    systemd.tmpfiles.rules = [
      "z ${cfg.configPath} 0600 diego media -"
    ];

    systemd.timers.proton-drive-backup = {
      description = "Daily Proton Drive backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "04:00";
        Persistent = true;
        Unit = "proton-drive-backup.service";
      };
    };
  };
}
