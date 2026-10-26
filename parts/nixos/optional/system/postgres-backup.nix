{ ... }:
{
  flake.modules.nixos.system-postgres-backup = { config, lib, ... }:

{
  # Copying a live postgres data directory with restic yields a torn, possibly
  # unrestorable snapshot, so dump instead and back the dumps up.
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    # Ahead of the restic run at 23:45 so each nightly snapshot picks up a
    # dump from the same day.
    startAt = "*-*-* 22:45:00";
  };

  backups.restic.sources = [ config.services.postgresqlBackup.location ];
};
}
