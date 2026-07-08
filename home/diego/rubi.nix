# Home Manager configuration for rubi (NixOS with Sway desktop)
{
  config,
  lib,
  pkgs,
  inputs,
  customPkgs,
  desktop ? null,
  privateConfig ? { },
  ...
}:
{
  colorscheme.type = "material-darker";

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
    ./features/ai
    ./features/ai/pixel-office.nix # Pixel Office dashboard + plugin (replaces Caffa blob-office)
    ./features/desktop/obsidian.nix
  ]
  ++ lib.optional (desktop != null) ./features/desktop/${desktop};

  home.packages = [
    customPkgs.clin
    customPkgs.coderabbit-cli
  ];

  # GTK bookmarks for file manager (using config.home.homeDirectory to avoid hardcoding)
  gtk.gtk3.bookmarks = [
    "file://${config.home.homeDirectory}/Documents"
    "file://${config.home.homeDirectory}/Downloads"
    "file://${config.home.homeDirectory}/Pictures"
    "file://${config.home.homeDirectory}/Projects"
  ];

  # OpenCode MCP configuration (managed by the nix-ai-tooling opencode-config module)
  # MCP servers are shared with Zed, Claude Code, Cursor, Antigravity via programs.mcp-config
  programs.opencode-config = {
    enable = true;

    # Work machine: work-provider inference only — no Go/Zen (personal resources)
    opencodeGo.enable = false;
    opencodeZen.enable = false;

    extraConfig = privateConfig.opencodeConfig or { };

    profiles =
      lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
        # opencode-work → work-provider inference only (work resources, from private-config)
        work = privateConfig.workProfile; # scriptName "ocw" comes from private repo
      }
      // {
        # opencode-personal → Go/Zen (Big Pickle) + Groq (no work resources)
        personal = {
          scriptName = "ocp";
          # Personal profile: no work MCP servers (project trackers etc.).
          # Only general + personal tooling. Keeps work
          # tool definitions out of personal-context sessions entirely.
          mcpServers = [
            "nixos"
            "telegram"
            "jobspy"
            "github"
            "playwright"
            "thunderbird"
          ];
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
            # Personal profile uses Big Pickle for all agents (no work resources)
            agent = (import ./features/ai/opencode-personal.nix).config.agent // {
              title.model = "opencode/big-pickle";
              summary.model = "opencode/big-pickle";
              compaction.model = "opencode/big-pickle";
              # Context-creep control: github (~dozens of tools, flagged by
              # opencode docs as a token hog) and playwright (~25 tools) are
              # disabled globally below and re-enabled only inside these
              # purpose-built subagents. Invoke with @browser / @github.
              browser = {
                description = "Web/browser automation via Playwright MCP (navigate, click, screenshot, scrape).";
                mode = "subagent";
                tools = {
                  "playwright_*" = true;
                };
              };
              github = {
                description = "GitHub operations via the GitHub MCP server (issues, PRs, repos).";
                mode = "subagent";
                tools = {
                  "github_*" = true;
                };
              };
            };
            # Disable the chatty MCP servers globally; they are re-enabled
            # per-agent above. The lean default keeps nixos/telegram/
            # jobspy hot (small tool counts) while gating the big ones.
            tools = {
              "github_*" = false;
              "playwright_*" = false;
            };
          };
        };
        # opencode-groq → Groq free tier (personal free resources)
        groq = {
          scriptName = "ocg";
          # Groq models are small/fast — keep the tool surface minimal to avoid
          # blowing the context window with MCP tool definitions.
          mcpServers = [
            "nixos"
          ];
          config = {
            model = "groq/llama-3.3-70b-versatile";
            small_model = "groq/llama-3.1-8b-instant";
            provider."groq" = {
              npm = "@ai-sdk/openai-compatible";
              name = "Groq";
              options = {
                baseURL = "https://api.groq.com/openai/v1";
                apiKey = "{env:GROQ_API_KEY}";
              };
              models = {
                "llama-3.3-70b-versatile" = {
                  name = "Llama 3.3 70B Versatile";
                };
                "llama-3.1-8b-instant" = {
                  name = "Llama 3.1 8B Instant";
                };
                "qwen3-32b" = {
                  name = "Qwen3 32B";
                };
                "gpt-oss-20b" = {
                  name = "GPT OSS 20B";
                };
              };
            };
            # Map agents by capability tier
            agent = {
              # Heavy reasoning tasks → large model
              build.model = "groq/llama-3.3-70b-versatile";
              plan.model = "groq/llama-3.3-70b-versatile";
              oracle.model = "groq/llama-3.3-70b-versatile";
              metis.model = "groq/llama-3.3-70b-versatile";
              momus.model = "groq/llama-3.3-70b-versatile";
              # General tasks → medium model
              explore.model = "groq/llama-3.1-8b-instant";
              general.model = "groq/llama-3.1-8b-instant";
              librarian.model = "groq/llama-3.1-8b-instant";
              prometheus.model = "groq/llama-3.1-8b-instant";
              # Lightweight tasks → fast model
              compaction.model = "groq/llama-3.1-8b-instant";
              summary.model = "groq/llama-3.1-8b-instant";
              title.model = "groq/llama-3.1-8b-instant";
            };
          };
        };
      };

    # Billing-context dispatcher (`oc`): routes to the right profile wrapper
    # script based on $OPENCODE_BILLING_CONTEXT. Neutral contexts are literal;
    # the work context is sourced from private-config (customer values live
    # there), keyed by the neutral keyword "work" — the old customer keyword
    # is dropped (type `work` instead). The work API-key env-var name and the
    # secretEnv entry backing it also come from private-config
    # (workInferenceEnvVar / workSecretEnv).
    dispatcher.contexts =
      {
        personal = {
          scriptName = "ocp";
          apiKeyEnvVar = "OPENCODE_API_KEY";
        };
        "opencode-go" = {
          scriptName = "ocp";
          apiKeyEnvVar = "OPENCODE_API_KEY";
        };
        groq = {
          scriptName = "ocg";
          apiKeyEnvVar = "GROQ_API_KEY";
        };
      }
      // lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
        work = {
          scriptName = privateConfig.workProfile.scriptName;
          apiKeyEnvVar = privateConfig.workInferenceEnvVar;
        };
      };

    # workSecretEnv already carries the work inference key entry, so no
    # customer-named literal is needed here.
    secretEnv = (privateConfig.workSecretEnv or { }) // {
      GROQ_API_KEY = "/run/secrets/groq-api-key";
    };

    # Skills are sourced from the vault via programs.ai-skills (all prompts migrated there).
    skills = { };
    agents =
      (import ./features/ai/gsd-core-agents.nix).agents // (import ./features/ai/coderabbit-agent.nix);
    # Pixel Office plugin (pixel-office.js) is provided by ./features/ai/pixel-office.nix
    commands = (import ./features/ai/gsd-core-agents.nix).commands // {
      "review" = ''
        ---
        description: Run CodeRabbit AI review on uncommitted changes or against base branch
        argument-hint: "[--type uncommitted | --base main]"
        tools:
          bash: true
        ---
        <objective>
        Run CodeRabbit CLI review on the current workspace.
        </objective>

        <context>
        User arguments: $ARGUMENTS
        </context>

        <process>
        1. Parse $ARGUMENTS:
           - If `--type uncommitted` or no flag: `cr review --agent --type uncommitted`
           - If `--base <branch>`: `cr review --agent --base <branch>`
           - Otherwise: `cr review --agent --type uncommitted`
        2. Run the command and capture JSON output
        3. Present findings in three tiers: **Critical**, **Warning**, **Info**
        4. If user asks to fix issues, suggest `/gsd-code-review --fix`
        </process>
      '';
    };
    references = (import ./features/ai/gsd-core-agents.nix).references;
  };

  programs.claude-code-config.commands = {
    "review" = {
      description = "Run CodeRabbit AI review on uncommitted changes or against base branch";
      prompt = "Run `cr review --agent --type uncommitted` (or `cr review --agent --base <branch>` if --base flag given) and present findings as Critical/Warning/Info tiers. If user asks to fix issues, point them to the findings and suggest addressing each manually.";
    };
  };

  programs.ai-skills.opencodeProfiles = [
    "work"
    "personal"
    "groq"
  ];

  # COSMIC-specific user configuration
  # COSMIC stores its config in ~/.config/cosmic/ (RON format)
  # These are managed at runtime by COSMIC Settings, but we can set defaults

  # Default cursor is managed by Stylix via features/desktop/common/stylix.nix
}
