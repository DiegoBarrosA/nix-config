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

  programs.claude-code-config.extraMcpServers."jira-dc" = {
    command = "${customPkgs.jira-data-center-mcp}/bin/jira-data-center-mcp";
    env = {
      BASE_URL = "\${JIRA_DC_BASE_URL}";
      EMAIL = "\${JIRA_DC_EMAIL}";
      API_KEY = "\${JIRA_DC_API_KEY}";
    };
  };

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
    personal = { };
    sr = {
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
