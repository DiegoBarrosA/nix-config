# Home Manager configuration for rubi (NixOS with Sway desktop)
{
  config,
  lib,
  pkgs,
  inputs,
  customPkgs,
  privateConfig ? { },
  ...
}:
{
  # Default to black-metal-dark-funeral.  The global specialisations (global/default.nix)
  # would force Gruvbox on `dark`/`light`; we set the default here so rubi always gets the
  # metal scheme regardless of specialisation.
  colorscheme.type = lib.mkDefault "black-metal-dark-funeral";

  imports = [
    # Rubi-local toggles for desktop setup.
    (
      { lib, ... }:
      {
        options.rubi.desktop.manageKanshi =
          lib.mkEnableOption ''
            Install Sway-style kanshi profiles (calls swaymsg).
          ''
          // {
            default = true;
          };
      }
    )
    ./global
    ./features/cli
    ./features/desktop/common # Firefox, Qt, Stylix
    ./features/desktop/sway # Sway desktop configuration
    ./features/ai
    ./features/desktop/obsidian.nix
  ];

  # GTK bookmarks for file manager (using config.home.homeDirectory to avoid hardcoding)
  gtk.gtk3.bookmarks = [
    "file://${config.home.homeDirectory}/Documents"
    "file://${config.home.homeDirectory}/Downloads"
    "file://${config.home.homeDirectory}/Pictures"
    "file://${config.home.homeDirectory}/Projects"
  ];

  # OpenCode MCP configuration (managed by modules/home-manager/opencode-config.nix)
  # MCP servers are shared with Zed, Claude Code, Cursor, Antigravity via programs.mcp-config
  programs.opencode-config = {
    enable = true;

    # Work machine: NVIDIA inference only — no Go/Zen (personal resources)
    opencodeGo.enable = false;
    opencodeZen.enable = false;

    extraConfig = privateConfig.opencodeConfig or { };

    profiles =
      lib.optionalAttrs ((privateConfig.rubiWorkProfile or null) != null) {
        # opencode-work → NVIDIA inference only (employer resources, from private-config)
        work = privateConfig.rubiWorkProfile; # scriptName "ocw" comes from private repo
      }
      // {
        # opencode-personal → Go/Zen (Big Pickle) + Groq (no employer resources)
        personal = {
          scriptName = "ocp";
          config = (import ./features/ai/opencode-personal.nix).config // {
            # profiles don't read opencodeGo/Zen options — include the providers explicitly
            provider."opencode-go" = {
              npm = "@ai-sdk/openai-compatible";
              name = "OpenCode Go";
              options = {
                baseURL = "https://opencode.ai/zen/go/v1";
                apiKey = "{env:OPENCODE_API_KEY}";
              };
              models = {
                "deepseek-v4-pro" = {
                  name = "DeepSeek V4 Pro";
                };
                "deepseek-v4-flash" = {
                  name = "DeepSeek V4 Flash";
                };
                "kimi-k2.6" = {
                  name = "Kimi K2.6";
                };
              };
            };
            provider."opencode" = {
              npm = "@ai-sdk/openai-compatible";
              name = "OpenCode Zen";
              options = {
                baseURL = "https://opencode.ai/zen/v1";
                apiKey = "{env:OPENCODE_API_KEY}";
              };
              models."big-pickle" = {
                name = "Big Pickle";
              };
            };
            provider."local-llm" = {
              npm = "@ai-sdk/openai-compatible";
              name = "Local LLM (llama.cpp)";
              options = {
                baseURL = "http://localhost:11435/v1";
                apiKey = "local";
              };
              models = {
                "qwen2.5-coder-7b" = {
                  name = "Qwen2.5 Coder 7B (local)";
                };
                "gemma3-4b" = {
                  name = "Gemma 3 4B (local)";
                };
              };
            };
            # Override light agent tasks to use local model — saves credits
            agent = (import ./features/ai/opencode-personal.nix).config.agent // {
              title.model = "local-llm/qwen2.5-coder-7b";
              summary.model = "local-llm/gemma3-4b";
            };
          };
        };
      };

    secretEnv = (privateConfig.rubiSecretEnv or { }) // {
      NVIDIA_API_KEY = "/run/secrets/nvidia-api-key";
      GROQ_API_KEY = "/run/secrets/groq-api-key";
    };

    # Skills are sourced from the vault via programs.ai-skills (all prompts migrated there).
    skills = { };
    agents = (import ./features/ai/gsd-core-agents.nix).agents;
    commands = (import ./features/ai/gsd-core-agents.nix).commands;
  };

  programs.ai-skills.opencodeProfiles = [
    "work"
    "personal"
  ];

  # COSMIC-specific user configuration
  # COSMIC stores its config in ~/.config/cosmic/ (RON format)
  # These are managed at runtime by COSMIC Settings, but we can set defaults

  # Default cursor is managed by Stylix via features/desktop/common/stylix.nix
}
