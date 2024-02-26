{ lib, ... }: {
  imports = [ ./containers.nix ./torrenting.nix ];
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    # dockerSocket.enable = true;
    # networkSocket.openFirewall = true;
  };
}
