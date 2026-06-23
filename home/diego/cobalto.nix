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
    ohMyOpencode = {
      enable = true;
      agentConfig.agents = (import ./features/ai/opencode-personal.nix).agents;
    };
    opencodeGo.enable = true;
    opencodeZen.enable = true;
    provider.enable = false;
    extraConfig = (import ./features/ai/opencode-personal.nix).config;
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
