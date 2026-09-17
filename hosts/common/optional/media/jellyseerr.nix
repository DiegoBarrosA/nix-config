{ config, lib, pkgs, ... }:

{

  virtualisation.oci-containers = {
    backend = "podman";
    containers.jellyseerr = {
      image = "fallenbagel/jellyseerr:latest";
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
