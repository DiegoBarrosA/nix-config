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

    extraSkillSources = [ "${inputs.obsidian-skills}/skills" ];
  };

  programs.ai-system-prompt = {
    enable = true;

  };
}
