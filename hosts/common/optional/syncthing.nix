{
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    dataDir = "/nix/storage/var/lib/syncthing";
  };
}
