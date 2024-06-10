{ lib, pkgs, ... }: {
  virtualisation = {
    containers.storage.settings = {
      storage = {
        driver = "overlay";
        runroot = "/run/containers/storage";
        graphroot = "/var/lib/containers/storage";
        rootless_storage_path = "/tmp/containers-$USER";
        options.overlay.mountopt = "nodev,metacopy=on";
      };
    };
    containers.enable = true;
    oci-containers.backend = "podman";
    podman = {
      extraPackages = [ pkgs.podman-compose ];
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
      dockerCompat = true;
      dockerSocket.enable = false;
    };

  };
  networking.firewall = {
    enable = true;
    interfaces."enp5s0" = {
      allowedTCPPorts = [ 8888 49999 9001 8098 ];
      allowedUDPPorts = [ 2376 49999 9001 8098 ];
    };
  };

}
