# Media Migration Runbook: /mnt/media → /srv/media + New Services

This runbook covers the physical migration, the NixOS switch, and post-switch validation steps.
It is written for the `cobalto` host.

---

## Phase 0: Pre-flight Checks

### 0.1 Library inventory

```bash
ssh cobalto
find /srv/media/library -type f \( -iname "*.mkv" -o -iname "*.mp4" \) | wc -l
find /srv/media/library -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -exec du -sh {} + | sort -h | tail -20
du -sh /srv/media/library/*
df -h /srv/media
```

### 0.2 GPU VAAPI encode capabilities

```bash
vainfo --show-usage
# Confirm at minimum: h264_vaapi (encode), hevc_vaapi (encode)
# Also check for: hevc_main10_vaapi (10-bit HEVC, Polaris may not have it)
```

If `hevc_vaapi` is absent or encode-only is missing, the Tdarr migration falls back to CPU x265.

### 0.3 Backup Jellyfin / Sonarr / Radarr config

```bash
# Jellyfin (if API key is known)
curl -H "X-Emby-Token: $JELLYFIN_KEY" http://localhost:8096/System/ServerConfig > /tmp/jellyfin-server-config.json

# Sonarr
curl -H "X-Api-Key: $(cat /run/secrets/sonarr-api-key)" http://localhost:8989/api/v3/system/status > /tmp/sonarr-status.json

# Radarr
curl -H "X-Api-Key: $(cat /run/secrets/radarr-api-key)" http://localhost:7878/api/v3/system/status > /tmp/radarr-status.json

# Prowlarr
curl -H "X-Api-Key: $(cat /run/secrets/prowlarr-api-key)" http://localhost:9696/api/v1/system/status > /tmp/prowlarr-status.json
```

### 0.4 Test single-file transcode (CPU fallback)

```bash
# Pick a small test file (~1 GB)
TEST_IN="/srv/media/library/movies/Test Movie (2024)/Test Movie (2024).mkv"
TEST_OUT="/tmp/test-transcode.mkv"

ffmpeg -i "$TEST_IN" \
  -vaapi_device /dev/dri/renderD128 \
  -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi -qp 25 -c:a copy \
  "$TEST_OUT"

ls -lh "$TEST_IN" "$TEST_OUT"
# Verify: file should be smaller, audio/subs preserved
# Play test_out in VLC to confirm quality
rm "$TEST_OUT"
```

---

## Phase 1: Physical Move (downtime window, ~15 minutes)

Stop all media services first:

```bash
sudo systemctl stop sonarr radarr lidarr prowlarr bazarr lazylibrarian \
  jellyfin qbittorrent transmission 2>/dev/null || true
```

### 1.1 Move library files

```bash
sudo mkdir -p /srv/media/library/movies
sudo mkdir -p /srv/media/library/series

sudo mv /mnt/media/Movies/* /srv/media/library/movies/ 2>/dev/null || true
sudo mv /mnt/media/Tv/* /srv/media/library/series/ 2>/dev/null || true
```

### 1.2 Move download directories

```bash
sudo mkdir -p /srv/media/downloads/complete/{movies,series,lidarr,lazylibrarian,bazarr}
sudo mkdir -p /srv/media/downloads/incomplete

sudo mv /mnt/media/Transmission/Downloads/* /srv/media/downloads/ 2>/dev/null || true
sudo mv /mnt/media/Transmission/Incomplete/* /srv/media/downloads/incomplete/ 2>/dev/null || true
sudo mv /mnt/media/Transmission/Watch/* /srv/media/downloads/ 2>/dev/null || true
```

### 1.3 Move remaining directories

```bash
for dir in Music Books Audiobooks Documents Obsidian Repos Archive Pictures Incoming; do
  sudo mv "/mnt/media/$dir" "/srv/media/" 2>/dev/null || true
done
```

### 1.4 Fix ownership (media user)

```bash
sudo chown -R media:media /srv/media
sudo chmod -R 750 /srv/media/library
sudo chmod -R 750 /srv/media/downloads
sudo chmod -R 755 /srv/media/Pictures
sudo chmod -R 755 /srv/media/Documents
sudo chmod -R 755 /srv/media/Obsidian
```

### 1.5 Fix servarr data directory ownership

```bash
sudo chown -R media:media /nix/storage/servarr
sudo chown -R media:media /nix/storage/{tdarr,qbittorrent,jellyseerr}
```

---

## Phase 2: NixOS Switch

Deploy the new configuration (contains all new service modules, media user, /srv/media paths, nginx vhosts):

```bash
cd ~/nix-config
git checkout media-stack
# Build and deploy
nixos-rebuild switch --flake .#cobalto
# OR via deploy-rs:
nix run .#deploy -- cobalto
```

After switch:
- transmission is disabled
- native qbittorrent is running as `media:media` on port 8080
- tdarr server + node are running as `media:media`
- jellyseerr is running as a podman container
- recyclarr timer is active (daily 3:00 AM)
- aria2 is running on port 6800

---

## Phase 3: Post-switch Reconfiguration

### 3.1 qBittorrent first login

```bash
# Check logs for the temporary password
journalctl -u qbittorrent --no-pager | grep -i password
```

Open `https://transmission.minerales.network` (legacy domain still works, now pointing at qBittorrent).

1. Login with `admin` / `<temp-password-from-logs>`
2. Change password immediately
3. Go to Settings → Downloads:
   - Default Save Path: `/srv/media/downloads`
   - Temp Path: `/srv/media/downloads`
   - Enable "Use another path for incomplete torrents": `/srv/media/downloads/incomplete`
4. Category mappings (Settings → Downloads → Save paths):
   - `movies` → `/srv/media/downloads/complete/movies`
   - `series` → `/srv/media/downloads/complete/series`

### 3.2 Sonarr reconfiguration

1. Open `https://sonarr.minerales.network`
2. Settings → Media Management → Root Folders:
   - Add: `/srv/media/library/series` (remove old `/mnt/media/Tv`)
3. Settings → Download Clients → Edit qBittorrent:
   - Host: `127.0.0.1`
   - Port: `8080`
   - Username: `admin`
   - Password: `<your qBittorrent password>`
4. Save → Test → OK

### 3.3 Radarr reconfiguration

1. Open `https://radarr.minerales.network`
2. Settings → Media Management → Root Folders:
   - Add: `/srv/media/library/movies` (remove old `/mnt/media/Movies`)
3. Settings → Download Clients → Edit qBittorrent (same credentials as Sonarr)

### 3.4 Jellyfin library rescan

1. Open `https://jellyfin.minerales.network`
2. Dashboard → Libraries → Edit each library:
   - Movies: change path from `/mnt/media/Movies` to `/srv/media/library/movies`
   - TV Shows: change path from `/mnt/media/Tv` to `/srv/media/library/series`
   - Music: change path to `/srv/media/library/music`
   - Books: change path to `/srv/media/library/books`
3. Click "Scan All Libraries"
4. Verify hardware transcoding: play a file, Dashboard → Playback → Transcoding, confirm "VAAPI"

### 3.5 Lidarr / Bazarr / LazyLibrarian

Same pattern: update root folder paths to `/srv/media/library/...` via their web UIs.

### 3.6 Jellyseerr

1. Open `https://jellyseerr.minerales.network`
2. First-run wizard: connect to Jellyfin (`http://127.0.0.1:8096`)
3. Connect Radarr and Sonarr (localhost, ports 7878/8989, API keys from Prowlarr)
4. Import Jellyfin users

### 3.7 Recyclarr validation

```bash
# Manually trigger a sync to verify
sudo systemctl start recyclarr.service
sudo journalctl -u recyclarr --no-pager -n 50
```

Confirm quality profiles appear in Sonarr/Radarr.

### 3.8 Tdarr validation

1. Open `https://tdarr.minerales.network`
2. Add library source: `/srv/media/library` (both movies and series)
3. Set cache directory: `/nix/storage/tdarr/cache`
4. Test a single small file transcode
5. Verify output plays correctly

---

## Phase 4: Tdarr Migration (Continuous Transcoding)

### 4.1 Configure migration plugin flow

In Tdarr web UI, create a flow:

1. **Filter**: `file.size > 5GB` OR `video.codec == h264`
2. **Transcode**: ffmpeg with VAAPI
   ```
   ffmpeg -i <input> -vaapi_device /dev/dri/renderD128 \
     -vf 'format=nv12,hwupload' \
     -c:v hevc_vaapi -qp 25 -c:a copy \
     <output>
   ```
3. **Replace**: move original to archive, replace with transcode
4. **Skip already processed**: enable library scan hash check

### 4.2 Schedule

Configure Tdarr scheduler: run 2 AM - 8 AM weekdays only.
Set concurrency: 2 GPU workers + 2 CPU workers (RX570 limit).

### 4.3 Monitor

```bash
# Check Tdarr node logs
journalctl -u tdarr-node-main --no-pager -f

# Monitor disk I/O during migration
iostat -x 1 10
```

### 4.4 Post-migration

1. Switch Tdarr to "new files only" mode
2. Verify library integrity: spot-check 10+ transcodes
3. Clean up archive originals after 1-week validation buffer

```bash
# After 1 week, archive originals (DO NOT DELETE until validated)
mkdir -p /srv/media/archive/originals
# Move originals from archive
mv /srv/media/archive/originals/ /srv/media/archive/originals-pre-migration/
```

---

## Appendix: Rollback

If something goes wrong:

1. Stop all new services: `sudo systemctl stop qbittorrent tdarr-server tdarr-node-main aria2 recyclarr`
2. Stop jellyseerr: `sudo podman stop media-jellyseerr`
3. If directory move was the issue, reverse it:
   ```bash
   sudo rsync -av /srv/media/ /mnt/media/
   ```
4. Redeploy the previous NixOS generation:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```
