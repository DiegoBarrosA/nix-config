{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.claude-code-config.enable = true;
  programs.cursor-config.enable = true;
  programs.antigravity-config.enable = true;

  programs.zed-editor-custom = {
    enable = true;
    enableMcpIntegration = true;
  };

  programs.ai-skills = {
    enable = true;
    # tools.* default to true; opencodeProfiles set per-host (rubi adds work/personal)
  };
}
