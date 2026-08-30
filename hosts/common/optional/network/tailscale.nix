{ config, pkgs, ... }:

{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-key".path;
    extraUpFlags = [
      "--ssh"
      "--accept-dns=true"
      "--accept-routes"
    ];
  };

  environment.systemPackages = with pkgs; [
    tailscale
  ];

}

