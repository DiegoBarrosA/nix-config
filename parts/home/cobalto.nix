{ config, ... }@top:
{
  flake.modules.homeManager.cobalto =
{
  config,
  pkgs,
  lib,
  customPkgs,
  inputs,
  theme ? null,
  privateConfig ? { },
  ...
}:
let

  aiSecretEnv = (privateConfig.workSecretEnv or { }) // {
    OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
    GITHUB_TOKEN = "/run/secrets/github-token";
  };

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

  # Token-based Claude accounts: personal here, work ones from the private repo.
  # Hermes wrappers for these live in ai/hermes-agent.nix.
  programs.claude-code-config = {
    # claude-agent-acp pulls in claude-code, which is unfree.
    acpPackage =
      (import inputs.nixpkgs-acp {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).claude-agent-acp;
    profiles =
      (privateConfig.workClaudeProfiles or { })
      // {
        personal.tokenFile = "/run/secrets/claude-token-personal";
      };
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
    # Headless server: no fonts, KDE or GNOME theming. Only enable CLI targets above.
    autoEnable = false;
  };
}

  ;
}
