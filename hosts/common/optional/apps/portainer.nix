{ config, lib, pkgs, ... }:

{
  # Portainer - Container management dashboard
  # Provides web UI for managing Docker/Podman containers
  
  # Enable Podman for container support
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;  # Disabled to avoid conflict with Docker service
    defaultNetwork.settings.dns_enabled = true;
  };
  
  virtualisation.oci-containers = {
    backend = "podman";
    
    containers = {
      # Portainer for container management
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
  
  # Ensure directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/containers/storage/volumes/portainer 0755 root root -"
  ];
  
  # Firewall
  networking.firewall.allowedTCPPorts = [ 8098 ];
}