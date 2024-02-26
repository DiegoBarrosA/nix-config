{
  virtualisation.oci-containers.containers = {
    qbittorrent = {
      image = "cr.hotio.dev/hotio/qbittorrent:latest";
      autoStart = true;
      environment = { };
      ports = [ "127.0.0.1:8001:8080" ];
      volumes = [
        "/nix/storage/var/lib/vols/qbittorrent/config:/config"
        "/nix/storage/var/lib/vols/qbittorrent/Downloads:/Downloads"
      ];
    };
  };

}
