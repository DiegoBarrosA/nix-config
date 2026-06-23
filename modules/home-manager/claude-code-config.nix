# Claude Code MCP configuration module for Home Manager
# Merges MCP servers into ~/.claude.json (user-scope)
# Consumes programs.mcp-config.standardFormat
#
# Note: ~/.claude.json is not fully managed by Nix because Claude Code
# stores runtime state there. This module uses an activation script to
# merge MCP servers into the existing file.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.claude-code-config;
  mcpCfg = config.programs.mcp-config;
  jsonFormat = pkgs.formats.json { };

  # Merge shared MCP servers with any Claude-specific extras
  mcpServersConfig = mcpCfg.standardFormat.mcpServers // cfg.extraMcpServers;

  # Generate the MCP servers JSON file (used by activation script)
  mcpServersJson = jsonFormat.generate "claude-code-mcp-servers.json" mcpServersConfig;
in
{
  options.programs.claude-code-config = {
    enable = lib.mkEnableOption "Claude Code MCP configuration";

    extraMcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Additional MCP servers specific to Claude Code (in standard MCP format).";
      example = lib.literalExpression ''
        {
          "custom-server" = {
            command = "npx";
            args = [ "-y" "my-mcp-server" ];
            env = {
              API_KEY = "''${MY_API_KEY}";
            };
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Store the MCP servers config for reference/debugging
    xdg.configFile."claude-code/mcp-servers.json" = {
      source = mcpServersJson;
    };

    # Activation script to merge MCP servers into ~/.claude.json
    home.activation.claudeCodeMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_CONFIG="$HOME/.claude.json"
      MCP_SERVERS_FILE="${mcpServersJson}"

      if [ -f "$CLAUDE_CONFIG" ]; then
        # Merge MCP servers into existing config
        ${pkgs.jq}/bin/jq -s '.[0] * {mcpServers: .[1]}' "$CLAUDE_CONFIG" "$MCP_SERVERS_FILE" > "$CLAUDE_CONFIG.tmp"
        mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"
        run echo "Claude Code: Updated MCP servers in $CLAUDE_CONFIG"
      else
        # Create new config with just MCP servers
        ${pkgs.jq}/bin/jq '{mcpServers: .}' "$MCP_SERVERS_FILE" > "$CLAUDE_CONFIG"
        run echo "Claude Code: Created $CLAUDE_CONFIG with MCP servers"
      fi
    '';
  };
}
