{ ... }:
{
  flake.modules.nixos.ai-ollama-native =
{ config, lib, pkgs, ... }:

{

  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    package = pkgs.ollama-rocm;

    environmentVariables = {

      OLLAMA_ORIGINS = "*";
    };

  };

  networking.firewall.allowedTCPPorts = [ 11434 ];

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];

  users.users.diego.extraGroups = [ "ollama" ];
}
  ;
}
