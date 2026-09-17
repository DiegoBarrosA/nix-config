# Post-deployment Checklist

Complete this after `nixos-rebuild switch` succeeds on cobalto.

---

## 1. Secrets verification

```bash
# Confirm all secrets exist in sops
sops -d /etc/secrets/aria2-rpc-secret
sops -d /etc/secrets/tdarr-server-env
sops -d /etc/secrets/tdarr-node-env
```

Add these to `hosts/cobalto/secrets.yaml` (encrypted) if not yet present.

---

## 2. Service health checks

```bash
# All services should be active
systemctl status qbittorrent tdarr-server tdarr-node-main aria2 recyclarr
systemctl status sonarr radarr lidarr prowlarr bazarr lazylibrarian
podman ps  # jellyseerr should be running
```

---

## 3. VAAPI hardware acceleration

```bash
vainfo --show-usage
# Confirm:
#   h264_vaapi (encode/decode)
#   hevc_vaapi (encode/decode)
#   vp9_vaapi  (decode)
#   av1_vaapi  (decode)

# Test via Jellyfin web UI:
# Play a file → Dashboard → Playback → Transcoding
# Confirm "VAAPI" appears under Video Decoder
```

---

## 4. qBittorrent seed bonus check

```bash
# Log in and verify torrent connectivity
curl -s http://localhost:8080/api/v2/transfer/info
# Should return JSON with "connected: true" for trackers
```

---

## 5. Jellyseerr → Jellyfin → Radarr → Sonarr chain

```bash
# Request a movie through Jellyseerr
# Confirm it appears in Radarr (auto-added)
# Confirm download starts in qBittorrent
# Confirm Sonarr picks up an episode if TV show
```

---

## 6. Recyclarr quality profiles

```bash
# Manually trigger first sync
sudo systemctl start recyclarr.service
journalctl -u recyclarr --no-pager -n 30
# Confirm no errors; check Sonarr/Radarr UI for updated profiles
```

---

## 7. Tdarr single-file test

```bash
# In Tdarr UI, queue a small file for transcode
# Monitor progress
# Verify output plays and metadata is preserved
```

---

## 8. Samba share access

From another machine on the LAN:
```bash
smbclient -L //cobalto -U diego
# Confirm: media, library, downloads, incoming, documents, obsidian shares visible
```

---

## 9. Syncthing resync

```bash
# Confirm all 7 folders are "Up to Date" in Syncthing web UI
# https://syncthing.minerales.network
```

---

## 10. Old disk space recovery

After 1-week validation:
```bash
# Check for orphaned /mnt/media remnants
ls -la /mnt/media/
# Remove legacy bind mount from hardware-configuration.nix if clean
```
