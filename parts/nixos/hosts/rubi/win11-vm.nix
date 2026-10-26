{ ... }:
{
  flake.modules.nixos.rubi-win11-vm = { inputs, lib, pkgs, config, ... }:

let
  nixvirt = inputs.nixvirt.lib;

  win11UUID = "a1b2c3d4-e5f6-4789-abcd-ef0123456789";
in
{

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.swtpm.enable = true;

  virtualisation.libvirt.connections."qemu:///system".domains = [
    {
      definition = nixvirt.domain.writeXML (nixvirt.domain.templates.windows {
        name = "win11";
        uuid = win11UUID;
        memory = { count = 8; unit = "GiB"; };
        storage_vol = "/var/lib/libvirt/images/win11.qcow2";
        install_vol = "/var/lib/libvirt/images/Win11.iso";
        nvram_path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
        virtio_net = true;
        virtio_drive = true;
        virtio_video = true;
        install_virtio = true;
      });
      active = null;
    }
  ];
};
}
