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
    # opencodeGo/Zen, extraConfig, profiles, secretEnv, skills, agents, commands, references set per-host

    # Disable auto-start for slow Python MCP servers (~1.6s mcp-nixos).
    # The upstream module hardcodes enabled=true for these; extraMcpServers merges last
    # so this override wins. Enable on demand via `opencode mcp`.
    extraMcpServers = {
      nixos = {
        type = "local";
        command = [ "${pkgs.mcp-nixos}/bin/mcp-nixos" ];
        enabled = false;
      };
    };
  };
}
