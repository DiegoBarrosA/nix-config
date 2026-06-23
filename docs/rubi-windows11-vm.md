# Windows 11 VM on rubi

This guide covers installing Windows 11 in the declaratively-defined VM on rubi using virt-manager.

## Prerequisites

1. **Windows 11 ISO** - Download from [microsoft.com](https://www.microsoft.com/software-download/windows11)
2. **virtio-win drivers** - The `win-virtio` package is installed; alternatively download from [fedorapeople.org](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/)

## ISO Placement

Place the ISOs at these paths (the declarative domain references them):

```bash
# Create the images directory (persisted via impermanence)
sudo mkdir -p /var/lib/libvirt/images

# Copy your ISOs
sudo cp ~/Downloads/Win11_*.iso /var/lib/libvirt/images/Win11.iso
sudo cp /run/current-system/sw/share/virtio-win/virtio-win.iso /var/lib/libvirt/images/virtio-win.iso
# Or download virtio-win manually if the package path differs
```

## Deploying the Configuration

```bash
# Rebuild and switch to activate libvirt + the Win11 domain
sudo nixos-rebuild switch --flake .#rubi

# Verify the domain exists
virsh list --all
# Expected: win11 domain in "shut off" state

# Verify OVMF + TPM configuration
virsh dumpxml win11 | grep -E "loader|tpm|virtio"
```

## Starting the VM

### Via virt-manager (recommended)

1. Launch virt-manager from your Sway launcher (wofi/rofi)
2. Connect to "QEMU/KVM" (should auto-connect)
3. Select the `win11` VM
4. Click "Open" to view console, then "Play" button to start

### Via command line

```bash
virsh start win11
virt-viewer win11
```

## Windows Installation

### During Setup

1. Boot from the Windows 11 ISO
2. Select language/region, click "Install now"
3. When prompted "Where do you want to install Windows?":
   - You'll see no drives (virtio-scsi needs a driver)
   - Click "Load driver" → "Browse"
   - Navigate to the virtio-win CD: `D:\amd64\w11\` (or `E:\`)
   - Select the Red Hat VirtIO SCSI controller driver
   - Click "Next" to load it
4. The virtual disk should now appear - select it and continue installation

### Post-Installation

1. Open the virtio-win CD in File Explorer (`D:` or `E:`)
2. Run `virtio-win-guest-tools.exe` to install all drivers
3. Reboot when prompted

## Verifying 3D Acceleration

The VM uses **virtio-gpu with VirGL/Venus** for 3D acceleration (paravirtualized, not GPU passthrough).

### In Windows

1. Open Device Manager → Display adapters
   - Should show "Red Hat VirtIO GPU" or similar
2. Run `dxdiag`:
   - Display tab → check DirectDraw/Direct3D acceleration status
3. Run a light 3D application to confirm

### Troubleshooting 3D

If you experience graphics issues (black screen, artifacts, crashes):

1. The 680M iGPU + Venus may be unstable; try disabling GL:
   ```bash
   virsh edit win11
   # Find <graphics type='spice'> and change:
   # <gl enable='yes'/> to <gl enable='no'/>
   ```
2. This falls back to software rendering but maintains stability

## Impermanence Note

VM state is persisted across reboots:
- `/var/lib/libvirt/images/` - VM disk images
- `/var/lib/libvirt/qemu/nvram/` - UEFI variable stores (secure boot state)
- `/var/lib/libvirt/swtpm/` - TPM state

These are covered by the `/var/lib/libvirt` persistence entry.

## Troubleshooting

### "This PC can't run Windows 11"

TPM or Secure Boot issue. Verify the domain has TPM:
```bash
virsh dumpxml win11 | grep -A5 "<tpm"
# Should show model='tpm-crb' or 'tpm-tis' with version='2.0'
```

### Black screen on boot

1. Try without 3D acceleration (see above)
2. Check SPICE is working: `virt-viewer --connect qemu:///system win11`

### No storage devices during install

Load the virtio-scsi driver from the virtio-win CD as described above.

### VM won't start - permission denied

Ensure your user is in the `libvirtd` group:
```bash
groups | grep libvirtd
# If missing (shouldn't be on rubi): sudo usermod -aG libvirtd $USER
```

## VM Specifications (Defaults)

The declarative domain defines:
- **CPU**: 4 vCPUs, host-passthrough
- **Memory**: 8 GiB
- **Disk**: 64 GiB virtio (qcow2)
- **Graphics**: virtio-gpu with VirGL, SPICE display
- **Network**: virtio NIC on default NAT
- **Firmware**: OVMF (UEFI, secure-boot capable)
- **TPM**: swtpm 2.0

Edit `/var/lib/libvirt/images/win11.qcow2` size or domain XML via `virsh edit win11` to adjust.
