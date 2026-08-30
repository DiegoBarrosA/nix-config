{ config, lib, pkgs, ... }:

{

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";

    containers = {

      portainer = {
        image = "portainer/portainer-ce:latest";
        autoStart = true;
        ports = [ "8098:9000" ];
        volumes = [
          "/var/lib/containers/storage/volumes/portainer:/data:rw"
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
        ];
        extraOptions = [
          "--privileged"
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/containers/storage/volumes/portainer 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 8098 ];
}