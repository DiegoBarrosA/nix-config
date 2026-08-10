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
    plugins = (import ./features/ai/session-character-visualizer.nix) { inherit pkgs; };

    # Personal + work: the work profile (ocw) uses employer NVIDIA inference
    # + the employer Atlassian MCPs, sourced from private-config (only added
    # when the private flake provides a workProfile — e.g. on cobalto).
    profiles =
      lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
        work = privateConfig.workProfile;
      };

    # `oc` dispatcher: personal contexts are literal; the work context is
    # sourced from private-config (workProfile.scriptName / workInferenceEnvVar),
    # keyed by the neutral keyword "work".
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

    # workSecretEnv carries the work inference key + all Atlassian MCP env
    # vars; merge with the personal keys so both `oc`/`ocp` and `ocw` work.
    secretEnv = (privateConfig.workSecretEnv or { }) // {
      OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
      GITHUB_TOKEN = "/run/secrets/github-token";
    };
  };

  # Jcode configuration — same Go/Zen providers as opencode on cobalto.
  programs.jcode-config = {
    enable = true;
    opencodeGo.enable = true;
    opencodeZen.enable = true;

    profiles =
      lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
        work = {
          scriptName = "jcw";
          mcpServers = null; # inherit all
          config = privateConfig.jcodeWorkConfig or { };
        };
      }
      // {
        personal = {
          scriptName = "jcp";
          mcpServers = null; # inherit all
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

    secretEnv = (privateConfig.workSecretEnv or { }) // {
      OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
      GITHUB_TOKEN = "/run/secrets/github-token";
    };
  };

  # Claude Code is enabled globally via features/ai (Atlassian MCPs injected
  # by workMcpConfig). Claude Desktop is NOT wanted on this headless host
  # (ai-tools.nix enables it globally, so force it off here).
  programs.claude-desktop-config.enable = lib.mkForce false;

  # Happy Coder daemon — keeps a background service that lets Claude/Codex
  # sessions be spawned/controlled from the phone (via happy's cloud relay).
  systemd.user.services.happy-daemon = {
    Unit = {
      Description = "Happy Coder daemon (mobile Claude/Codex control)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      # start-sync runs the daemon in the foreground (systemd manages it);
      # `happy daemon start` detaches a child instead.
      ExecStart = "${pkgs.happy-coder}/bin/happy daemon start-sync";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = (with pkgs; [
    uv
    mcp-nixos
    nodejs_24
    ripgrep
    resumed
    playwright-mcp
    happy-coder
  ]);

  colorscheme = {
    type = "material-darker";
    mode = "dark";
  };
}
