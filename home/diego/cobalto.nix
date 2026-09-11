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
          config = (import ./features/ai/opencode-personal.nix).config;
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
      claude.enable = true;
      opencode.enable = true;
      jcode.enable = true;
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
    base16Scheme = builtins.mapAttrs (_: c: "#${c}") config.colorscheme.colors;
    polarity = config.colorscheme.mode;
    targets = {
      gtk.enable = false;
      helix.enable = true;
    };
    overlays.enable = false;
  };
}
