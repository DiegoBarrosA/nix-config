{ config, ... }@top:
{
  flake.modules.homeManager.cobalto =
{
  config,
  pkgs,
  lib,
  customPkgs,
  theme ? null,
  privateConfig ? { },
  ...
}:
let

  aiSecretEnv = (privateConfig.workSecretEnv or { }) // {
    OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
    GITHUB_TOKEN = "/run/secrets/github-token";
  };

  happySecretEnv = lib.removeAttrs aiSecretEnv [
    "ANTHROPIC_API_KEY"
    "NVIDIA_API_KEY"
    "OPENCODE_API_KEY"
  ];
in
{
  imports = with top.config.flake.modules.homeManager; [
    global
    cli
    ai
  ];

  programs.opencode-config = {
    enable = true;
    opencodeGo.enable = true;
    opencodeZen.enable = true;
    provider.enable = false;
    extraConfig = (import ./features/ai/_opencode-personal.nix).config;

    profiles =
      lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
        work = privateConfig.workProfile;
      };

    dispatcher.contexts = {
      personal = {
        scriptName = "ocp";
        apiKeyEnvVar = "OPENCODE_API_KEY";
      };
    }
    // lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
      work = {
        scriptName = privateConfig.workProfile.scriptName;
        apiKeyEnvVar = privateConfig.workInferenceEnvVar;
      };
    };

    secretEnv = aiSecretEnv;
  };

  programs.jcode-config = {
    enable = true;
    opencodeGo.enable = true;
    opencodeZen.enable = true;

    profiles =
      lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
        work = {
          scriptName = "jcw";
          mcpServers = null;
          config = privateConfig.jcodeWorkConfig or { };
        };
      }
      // {
        personal = {
          scriptName = "jcp";
          mcpServers = null;
          config = (import ./features/ai/_opencode-personal.nix).config;
        };
      };

    dispatcher.contexts = {
      personal = {
        scriptName = "jcp";
        apiKeyEnvVar = "OPENCODE_API_KEY";
      };
    }
    // lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
      work = {
        scriptName = "jcw";
        apiKeyEnvVar = privateConfig.workInferenceEnvVar;
      };
    };

    secretEnv = aiSecretEnv;
  };

  programs.claude-desktop-config.enable = lib.mkForce false;

  programs.happier-config = {
    enable = true;

    package = customPkgs.happier;

    server = {
      name = "happier-cloud";
      useByDefault = true;
    };

    daemon.enable = true;

    providers = {
      claude.enable = false;
      opencode.enable = false;
      jcode.enable = false;
      codex.enable = false;
      gemini.enable = false;
    };

    secretEnv = happySecretEnv;
  };

  home.packages = (with pkgs; [
    uv
    mcp-nixos
    nodejs_24
    ripgrep
    resumed
    playwright-mcp
  ]);

  colorscheme = {
    type = theme.scheme or "material-darker";
    mode = theme.mode or "dark";
  };

  stylix = {
    enable = true;
    base16Scheme =
      let
        baseKeys = [
          "base00"
          "base01"
          "base02"
          "base03"
          "base04"
          "base05"
          "base06"
          "base07"
          "base08"
          "base09"
          "base0A"
          "base0B"
          "base0C"
          "base0D"
          "base0E"
          "base0F"
        ];
      in
      lib.genAttrs baseKeys (k: "#${config.colorscheme.colors.${k}}");
    polarity = config.colorscheme.mode;
    targets = {
      gtk.enable = false;
      helix.enable = true;
    };
    overlays.enable = false;
  };
}

  ;
}
