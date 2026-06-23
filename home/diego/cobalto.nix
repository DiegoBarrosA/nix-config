{
  pkgs,
  lib,
  customPkgs,
  privateConfig ? { },
  ...
}:
{
  imports = [
    ./global
    ./features/cli
    ./features/ai
  ];

  programs.opencode-config = {
    enable = true;
    opencodeGo.enable = true;
    opencodeZen.enable = true;
    provider.enable = false;
    extraConfig = (import ./features/ai/opencode-personal.nix).config;
    agents = (import ./features/ai/gsd-core-agents.nix).agents;
    commands = (import ./features/ai/gsd-core-agents.nix).commands;
    references = (import ./features/ai/gsd-core-agents.nix).references;
    secretEnv = {
      OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
      GROQ_API_KEY = "/run/secrets/groq-api-key";
      OBSIDIAN_API_KEY = "/run/secrets/obsidian-api-key";
      GITHUB_TOKEN = "/run/secrets/github-token";
    };
  };

  home.packages = with pkgs; [
    uv
    mcp-nixos
    nodejs_24
    ripgrep
    resumed
    github-mcp-server
    playwright-mcp
  ];

  colorscheme = {
    type = "material-darker";
    mode = "dark";
  };
}
