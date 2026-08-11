{
  pkgs,
  lib,
  customPkgs,
  privateConfig ? { },
  ...
}:
let
  # workSecretEnv carries the work inference key + all Atlassian MCP env vars;
  # merge with the personal keys so every AI tool on this host sees both sets.
  aiSecretEnv = (privateConfig.workSecretEnv or { }) // {
    OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
    GITHUB_TOKEN = "/run/secrets/github-token";
  };

  # Env for phone-spawned sessions. Claude Code and Codex both authenticate
  # from their own on-disk credentials (~/.claude/.credentials.json and
  # ~/.codex/auth.json), so the inference keys are deliberately dropped here:
  # exporting ANTHROPIC_API_KEY would make claude bill the employer key
  # instead of the subscription, which is not what the default profile does
  # in an interactive shell. What is left is what the MCP servers need.
  happySecretEnv = lib.removeAttrs aiSecretEnv [
    "ANTHROPIC_API_KEY"
    "NVIDIA_API_KEY"
    "OPENCODE_API_KEY"
  ];

  # systemd user services inherit no shell profile, so the secrets the MCP
  # servers reference as ${VAR} have to be read from /run/secrets here.
  # Missing files are skipped, which keeps this safe if a secret is absent.
  happyDaemonStart = pkgs.writeShellScript "happy-daemon-start" ''
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: path: ''
        if [ -r "${path}" ]; then
          export ${name}="$(${pkgs.coreutils}/bin/cat "${path}")"
        fi
      '') happySecretEnv
    )}

    # start-sync runs the daemon in the foreground (systemd manages it);
    # `happy daemon start` detaches a child instead.
    exec ${pkgs.happy-coder}/bin/happy daemon start-sync
  '';
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

    # Both `oc`/`ocp` and `ocw` need the work + personal keys.
    secretEnv = aiSecretEnv;
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

    secretEnv = aiSecretEnv;
  };

  # Claude Code is enabled globally via features/ai (Atlassian MCPs injected
  # by workMcpConfig). Claude Desktop is NOT wanted on this headless host
  # (ai-tools.nix enables it globally, so force it off here).
  programs.claude-desktop-config.enable = lib.mkForce false;

  # Happy Coder daemon — keeps a background service that lets Claude/Codex
  # sessions be spawned/controlled from the phone (via happy's cloud relay).
  #
  # The daemon spawns `claude` or `codex` from PATH, picked per session from
  # the phone, so both run on their default profiles (~/.claude, ~/.codex).
  # It never invokes the ocp/ocw/jcp/jcw wrappers, so the env those wrappers
  # would have set has to come from the unit instead (see happyDaemonStart).
  systemd.user.services.happy-daemon = {
    Unit = {
      Description = "Happy Coder daemon (mobile Claude/Codex control)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${happyDaemonStart}";
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
