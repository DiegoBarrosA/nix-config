{ ... }:
{
  flake.modules.homeManager.ai-opencode =
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.opencode-config = {
    enable = true;
    channels.telegram.enable = true;
    notifications.telegram = {
      enable = true;
      enableShellHook = false;
    };
    provider.enable = false;

    extraMcpServers = {
      nixos = {
        type = "local";
        command = [ "${pkgs.mcp-nixos}/bin/mcp-nixos" ];
        enabled = false;
      };
    };
  };
};
}
