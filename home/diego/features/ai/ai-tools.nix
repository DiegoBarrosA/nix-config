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
  # obsidian MCP mirrors the claude-desktop-config entry below so both tools
  # get it from the declared set (otherwise the prune removes it from
  # ~/.claude.json). Credentials come from secretEnv; Claude Code expands
  # ${VAR} itself.
  programs.claude-code-config.extraMcpServers.obsidian = {
    command = "uvx";
    args = [ "mcp-obsidian" ];
    env = {
      OBSIDIAN_API_KEY = "\${OBSIDIAN_API_KEY}";
      OBSIDIAN_HOST = "127.0.0.1";
      OBSIDIAN_PORT = "27123";
    };
  };

  programs.claude-desktop-config = {
    enable = true;
    # Obsidian MCP: uses uvx (available everywhere). Credentials come from
    # secretEnv (set per-host in e.g. rubi.nix) so no hardcoded values here.
    extraMcpServers.obsidian = {
      command = "uvx";
      args = [ "mcp-obsidian" ];
      env = {
        OBSIDIAN_API_KEY = "\${OBSIDIAN_API_KEY}";
        OBSIDIAN_HOST = "127.0.0.1";
        OBSIDIAN_PORT = "27123";
      };
    };
  };
  programs.cursor-config.enable = true;
  programs.antigravity-config.enable = true;
  programs.jcode-config.enable = true;

  programs.ai-skills = {
    enable = true;
    # tools.* default to true (opencode/codex/claude/cursor/antigravity);
    # opencodeProfiles set per-host (rubi adds work/personal).
    # kepano/obsidian-skills: obsidian-markdown, obsidian-bases, json-canvas,
    # obsidian-cli, defuddle. Merged alongside the vault skills.
    extraSkillSources = [ "${inputs.obsidian-skills}/skills" ];
  };

  programs.ai-system-prompt = {
    enable = true;
    # vaultPromptsDir defaults to ~/Notes/AI/Prompts
    # System/*.md files are concatenated in alphabetical order:
    #   01-identity.md, 03-tools.md, Writing Style Rules.md
    # tools.claude, tools.cursor, tools.antigravity all default to true
  };
}
