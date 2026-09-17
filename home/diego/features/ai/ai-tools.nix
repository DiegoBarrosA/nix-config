{
  config,
  lib,
  pkgs,
  customPkgs,
  inputs,
  ...
}:
{
  programs.claude-code-config.enable = true;

  programs.claude-code-config.extraMcpServers."jira-dc" = {
    command = "${customPkgs.jira-data-center-mcp}/bin/jira-data-center-mcp";
    env = {
      BASE_URL = "\${JIRA_DC_BASE_URL}";
      EMAIL = "\${JIRA_DC_EMAIL}";
      API_KEY = "\${JIRA_DC_API_KEY}";
    };
  };

  programs.claude-desktop-config = {
    enable = true;
  };
  programs.cursor-config.enable = true;
  programs.antigravity-config.enable = true;
  programs.jcode-config.enable = true;

  programs.ai-skills = {
    enable = true;

    extraSkillSources = [
      "${inputs.obsidian-skills}/skills"
      "${inputs.impeccable}/.claude/skills"
    ];
  };

  programs.claude-code-config = {
    # Impeccable ships its subagents outside the skill folder itself.
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

  programs.ai-system-prompt = {
    enable = true;

  };
}
