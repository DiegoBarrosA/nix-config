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
  # jira-dc intentionally has no env block in the shared MCP config (opencode
  # double-spawn bug — {env:...} placeholders arrive unexpanded on first spawn).
  # Claude Code expands ${VAR} itself, so we inject the env block here only.
  programs.claude-code-config.extraMcpServers."jira-dc" = {
    command = "${customPkgs.jira-data-center-mcp}/bin/jira-data-center-mcp";
    env = {
      BASE_URL = "\${JIRA_DC_BASE_URL}";
      EMAIL = "\${JIRA_DC_EMAIL}";
      API_KEY = "\${JIRA_DC_API_KEY}";
    };
  };
  programs.cursor-config.enable = true;
  programs.antigravity-config.enable = true;

  programs.zed-editor-custom = {
    enable = true;
    enableMcpIntegration = true;
  };

  programs.ai-skills = {
    enable = true;
    # tools.* default to true (opencode/codex/claude/cursor/antigravity);
    # opencodeProfiles set per-host (rubi adds work/personal).
    # kepano/obsidian-skills: obsidian-markdown, obsidian-bases, json-canvas,
    # obsidian-cli, defuddle. Merged alongside the vault skills.
    extraSkillSources = [ "${inputs.obsidian-skills}/skills" ];
  };
}
