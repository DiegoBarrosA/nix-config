# Container Troubleshooting Steps

## 1. Jellyfin (GPU Device Issue)

### Check GPU devices exist:
```bash
ls -la /dev/dri/
lspci | grep -i vga
lspci | grep -i amd
```

### Check GPU setup service:
```bash
sudo journalctl -u gpu-setup -n 100
sudo systemctl status gpu-setup
```

### Check kernel modules:
```bash
lsmod | grep amdgpu
dmesg | grep amdgpu
```

### Try starting without GPU:
Edit `/home/diego/Documents/Repositories/nix-config/hosts/common/optional/enhanced-oci.nix` and comment out the GPU device lines, then deploy.

### Start manually:
```bash
sudo systemctl start podman-jellyfin
sudo journalctl -u podman-jellyfin -f
```

## 2. Transmission & Prowlarr (Exit Code 126 - Permission Issue)

Exit code 126 means "cannot execute" - usually a permission or missing executable issue.

### Check logs:
```bash
sudo journalctl -u podman-transmission -n 100
sudo journalctl -u podman-prowlarr -n 100
```

### Check storage permissions:
```bash
ls -la /nix/storage/transmission/
ls -la /nix/storage/servarr/prowlarr/
ls -la /mnt/media/transmission/
```

### Check ACLs:
```bash
getfacl /nix/storage/transmission/
getfacl /nix/storage/servarr/prowlarr/
```

### Manually set permissions:
```bash
sudo chmod -R 755 /nix/storage/transmission/
sudo chmod -R 755 /nix/storage/servarr/prowlarr/
sudo setfacl -R -m u:1000:rwx /nix/storage/transmission/
sudo setfacl -R -m u:1000:rwx /nix/storage/servarr/prowlarr/
```

### Try starting:
```bash
sudo systemctl start podman-transmission
sudo systemctl start podman-prowlarr
```

## 3. Text-generation-webui (Exit Code 125 - Container Error)

### Check logs:
```bash
sudo journalctl -u podman-text-generation-webui -n 100
```

### Check storage:
```bash
ls -la /nix/storage/llm/text-generation-webui/
ls -la /nix/storage/llm/models/
```

### Try pulling image manually:
```bash
sudo podman pull atinoda/text-generation-webui:default
```

### Check if GPU devices are needed:
```bash
ls -la /dev/kfd
ls -la /dev/dri/
```

## 4. Watchtower (Exit Code 1)

### Check logs:
```bash
sudo journalctl -u podman-watchtower -n 100
```

### Check Docker socket:
```bash
ls -la /var/run/docker.sock
```

### Try manual start:
```bash
sudo systemctl start podman-watchtower
```

## General Container Debugging

### Check podman status:
```bash
sudo systemctl status podman
sudo podman ps -a
sudo podman images
```

### Check storage preparation services:
```bash
sudo systemctl status prepare-container-storage
sudo systemctl status prepare-servarr-storage
sudo systemctl status prepare-llm-storage
```

### Check container networks:
```bash
sudo podman network ls
sudo podman network inspect podman
```

### Manual container start (example for jellyfin):
```bash
sudo podman run -d \
  --name jellyfin-test \
  -v /nix/storage/jellyfin/config:/config \
  -v /nix/storage/jellyfin/cache:/cache \
  -v /mnt/media:/media:ro \
  -p 8096:8096 \
  jellyfin/jellyfin:latest
```
