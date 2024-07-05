{
  services.tailscale = {
    enable = true;
    authKeyFile = "/nix/storage/run/secrets/tailscale_key";
  };
}
