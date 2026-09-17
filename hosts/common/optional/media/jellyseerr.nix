{ config, lib, pkgs, ... }:

{

  virtualisation.oci-containers = {
    backend = "podman";
    containers.jellyseerr = {
      # Fully qualified: podman has no unqualified-search registries configured,
      # so a bare "fallenbagel/..." short name fails to resolve on pull.
      image = "docker.io/fallenbagel/jellyseerr:latest";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      volumes = [
        "/nix/storage/jellyseerr:/app/config"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /nix/storage/jellyseerr 0770 media media -"
  ];

}
