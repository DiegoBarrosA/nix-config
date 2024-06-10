{
  services.transmission = {
    enable = true;
    group = "transmission";
    home = "/nix/storage/var/lib/transmission";
    downloadDirPermissions = "770";
    settings = {
      watch-dir-enabled = true;
      openRPCPort = true;
      watch-dir = "/home/diego/Downloads";
      trash-original-torrent-files = true;
      rpc-bind-address = "::";
      rpc-whitelist-enabled = false;
    };
  };
}
