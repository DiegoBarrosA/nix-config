# Declarative Windows 11 VM domain using NixVirt
# This defines a Win11-ready VM with UEFI, TPM 2.0, and virtio-gpu acceleration
{ inputs, lib, pkgs, config, ... }:

let
  nixvirt = inputs.nixvirt.lib;
  
  # Generate a stable UUID from the hostname (or use a fixed one)
  win11UUID = "a1b2c3d4-e5f6-4789-abcd-ef0123456789";
in
{
  # Enable NixVirt
  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.swtpm.enable = true;  # Required for TPM 2.0

  # Define the Windows 11 domain
  virtualisation.libvirt.connections."qemu:///system".domains = [
    {
      definition = nixvirt.domain.writeXML (nixvirt.domain.templates.windows {
        name = "win11";
        uuid = win11UUID;
        memory = { count = 8; unit = "GiB"; };
        storage_vol = "/var/lib/libvirt/images/win11.qcow2";
        install_vol = "/var/lib/libvirt/images/Win11.iso";
        nvram_path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
        virtio_net = true;       # Fast networking (driver included in virtio-win)
        virtio_drive = true;     # Fast storage (need to load driver during install)
        virtio_video = true;     # virtio-gpu for 3D acceleration
        install_virtio = true;   # Mount virtio-win ISO as second CDROM
      });
      active = null;  # Don't auto-start; user controls via virt-manager
    }
  ];
}
