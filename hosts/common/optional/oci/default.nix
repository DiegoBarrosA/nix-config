{ lib, pkgs, ... }: {
  imports = [ ./torrenting.nix ];
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
      networkSocket = {
        openFirewall = true;
        port = 2376;
        listenAddress = "0.0.0.0";
        enable = true;
        server = "ghostunnel";
        tls = {
          cert = "/home/diego/Documents/cert/server-cert.pem";
          cacert = "/home/diego/Documents/cert/ca.pem";
          key = "/home/diego/Documents/cert/server-key.pem";

        };
      };
    };

  };
  environment.systemPackages = [ pkgs.openssl ];
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
      export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    fi
  '';
  networking.firewall = {
    enable = true;
    interfaces."enp5s0" = {
      allowedTCPPorts = [ 8888 49999 9001 8098 ];
      allowedUDPPorts = [ 2376 49999 9001 8098 ];
    };
  };

}
