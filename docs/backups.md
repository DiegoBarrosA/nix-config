# Backups: restic to Cloudflare R2

Vaultwarden (and future services) are backed up by `services.backups-restic`
on cobalto:

1. `backup-vaultwarden.timer` (23:00) produces a consistent local dump in
   `/nix/storage/vaultwarden/backups` (sqlite `.backup` + attachments).
2. `backups-restic.timer` (23:45) snapshots that directory into a **local**
   restic repo at `/nix/storage/restic/`, then `restic copy` mirrors new
   snapshots into the **remote** repo on Cloudflare R2
   (`s3:<account-id>.r2.cloudflarestorage.com/bitwarden-backup`).
3. Retention: keep 30 daily / 12 weekly / 6 monthly with prune, applied to
   both repos.

Both repos are encrypted by restic (AES-256). Passwords live in
`hosts/cobalto/secrets.yaml` (`restic-local-password`,
`restic-remote-password`). R2 credentials: `r2-account-id`, `r2-access-key`,
`r2-secret-key`.

## Replace placeholder R2 credentials

The repo ships with `REPLACE_R2_*` placeholders so the pipeline is fully
wired without waiting on setup. To activate the offsite leg:

1. Cloudflare dashboard -> R2 -> Manage R2 API Tokens -> create a token
   scoped to the `bitwarden-backup` bucket (Object Read & Write, account
   scope). Copy the Access Key ID and Secret.
2. Find your Cloudflare **account id** (R2 overview page).
3. Edit secrets:
   ```
   cd hosts/cobalto
   sops edit secrets.yaml
   ```
   set `r2-access-key`, `r2-secret-key`, `r2-account-id`.
4. Redeploy cobalto, then:
   ```
   sudo systemctl start backups-restic.service
   ```
   It will init the remote repo on first remote-enabled run and copy all
   local snapshots.

## Restore to a fresh machine

```bash
export AWS_ACCESS_KEY_ID=<r2-access-key>
export AWS_SECRET_ACCESS_KEY=<r2-secret-key>
export AWS_DEFAULT_REGION=auto
END=s3:https://<r2-account-id>.r2.cloudflarestorage.com/bitwarden-backup
PW=<(echo -n "<restic-remote-password>")

restic -r "$END" --password-file "$PW" snapshots

restic -r "$END" --password-file "$PW" restore latest:/ /restore
```

Note: restic >= 0.17 takes the S3 endpoint from the repo URL and the region
from `AWS_DEFAULT_REGION`; the old `-o s3.endpoint=...` flag is gone.

Restored content under `/restore/nix/storage/vaultwarden/backups/` maps to
vaultwarden's data dir: `db.sqlite3`, `rsa_key.pem`, `attachments/`, `tmp/`.
Point a vaultwarden `dataDir` at that directory (or rsync it into
`/var/lib/bitwarden_rs`) and start the service.

## Add another service to backups

Append its directory to `backups.restic.sources` in the consuming module,
e.g. for couchdb:

```nix
backups.restic.sources = [ "/nix/storage/vaultwarden/backups" "/nix/storage/couchdb/backups" ];
```

Nothing else changes; the module handles init, copy, retention, and pruning.

## Checks

- Manual run: `sudo systemctl start backups-restic.service`
- Local snapshots: `sudo restic -r /nix/storage/restic --password-file /run/backups-restic/local snapshots`
  (only exists while the service runs; else read the password from sops)
- Remote snapshots: `restic list snapshots` from a machine with the env vars above.
- Systemd failure (OnFailure fires into the journal): `journalctl -u backups-restic.service -b`.