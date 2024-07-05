{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.arion ];
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
      dockerSocket.enable = true;
    };
  };
  networking.firewall = {
    enable = true;
    interfaces."enp5s0" = {
      allowedTCPPorts = [ 8384 8888 49999 9001 8098 ];
      allowedUDPPorts = [ 8384 2376 49999 9001 8098 ];
    };
  };

  virtualisation.oci-containers.containers = {
    portainer = {
      image = "portainer/portainer-ce:latest";
      volumes = [ "/nix/storage/var/lib/vols/portainer:/data" ];
      ports = [ "8098:9000" ];

    };
    portainer-agent = {
      image = "portainer/agent";
      volumes = [
        "/nix/storage/var/lib/volumes:/var/lib/docker/volumes"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      ports = [ "9001:9001" ];

    };

  };

}
