{
  virtualisation.oci-containers.containers = {
    portainer = {
      image = "portainer/portainer-ce:latest";
      autoStart = true;
      environment = { };
      ports = [ "127.0.0.1:9001:8080" ];
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    };
  };

}

