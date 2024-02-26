{lib, ... }:
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {

    freshrss = {
            image = "lscr.io/linuxserver/freshrss:latest";
      autoStart = true;
      ports = [ "127.0.0.1:49999:80" ];
      volumes = [ "/storage/var/lib/vols/freshrss:/config"
                ];
    };


    jellyfin = {
      image = "docker.io/jellyfin/jellyfin:latest";
      autoStart = true;
      ports = [ "127.0.0.1:8098:8096" ];
      volumes = [ "/storage/var/lib/vols/jellyfin/cache:/cache"
                  "/storage/var/lib/vols/jellyfin/config:/config"
                ];
    };
    yacreaderlib = {
      image = "docker.io/xthursdayx/yacreaderlibrary-server-docker";
      autoStart = true;
      ports = [ "127.0.0.1:8150:8080" ];
      volumes = [ "/storage/var/lib/vols/yacreader-lib/manga:/manga"
                  "/storage/var/lib/vols/yacreader-lib/config:/config"
                ];
      extraOptions =["--network=host"]; 
    };

  };
networking.firewall = {
    enable = true;

    interfaces."enp5s0" = {
    allowedTCPPorts = [ 49999 8001 8098 ];
    
  };
};
}
