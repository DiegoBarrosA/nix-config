{ ... }:
{
  flake.modules.homeManager.ai-ai-tools =
{
  config,
  lib,
  pkgs,
  customPkgs,
  inputs,
  ...
}:
{
  # Claude Code
  programs.claude-code-config.enable = true;

  home.packages = [ pkgs.pi-coding-agent ];

  programs.claude-code-config = {
    # Impeccable agents
    extraAgentSources = [ "${inputs.impeccable}/.claude/agents" ];

    enabledPlugins = {
      "superpowers@claude-plugins-official" = true;
      "ponytail@ponytail" = true;
    };

    extraKnownMarketplaces = {
      ponytail = {
        source = {
          source = "github";
          repo = "DietrichGebert/ponytail";
        };
      };
    };
  };

  # Extra profiles: ~/.config/claude-code-<name>, launched via claude-<name>.
  # They do not inherit the default profile's MCP servers.
  programs.claude-code-config.profiles = {
    # Plugins are per profile too, so repeat the default set here.
    personal = {
      inherit (config.programs.claude-code-config) enabledPlugins extraKnownMarketplaces;
    };
    sr = {
      # Same MCP set as the default profile (mirrors the module's own merge).
      mcpServers =
        config.programs.mcp-config.standardFormat.mcpServers
        // config.programs.claude-code-config.extraMcpServers;
      enabledPlugins."obsidian@obsidian-skills" = true;
      extraKnownMarketplaces."obsidian-skills".source = {
        source = "github";
        repo = "kepano/obsidian-skills";
      };
    };
  };

  # Cursor
  programs.cursor-config.enable = true;

  # Antigravity
  programs.antigravity-config.enable = true;

  # MCP servers
  programs.mcp-config = {
    enable = true;
    xContext.enable = true;
  };

  # Skills
  programs.ai-skills = {
    enable = true;

    extraSkillSources = [
      "${inputs.obsidian-skills}/skills"
      "${inputs.impeccable}/.claude/skills"
    ];
  };

  # System prompt
  programs.ai-system-prompt.enable = true;
};
}
