# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  fonts = import ./fonts.nix;
  monitors = import ./monitors.nix;
  colors = import ./colors.nix;
  obsidian-config = import ./obsidian-config.nix;
  opencode-config = import ./opencode-config.nix;
  mcp-config = import ./mcp-config.nix;
  # MCP config generators for other AI coding tools
  claude-code-config = import ./claude-code-config.nix;
  cursor-config = import ./cursor-config.nix;
  antigravity-config = import ./antigravity-config.nix;
  ai-skills = import ./ai-skills.nix;
}
