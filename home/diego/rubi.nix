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
  colorscheme.mode = "dark";
  colorscheme.type = "colors";
  colorscheme.iconFolderColor = "black";
  colorscheme.specialisations = { };

  imports = [

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

    ./features/cli/ekphos-theme.nix
    ./features/desktop/common
    ./features/desktop/common/chromium
    ./features/desktop/zennotes-theme.nix
    ./features/ai
    ./features/audio

  ]
  ++ lib.optional (desktop != null) ./features/desktop/${desktop};

  home.packages = [

    customPkgs.coderabbit-cli
    customPkgs.claude-desktop
    customPkgs.personal-assistant
    pkgs.zed-editor-fhs

    customPkgs.ekphos

    pkgs.nodejs_24
  ];

  gtk.gtk3.bookmarks = [
    "file://${config.home.homeDirectory}/Documents"
    "file://${config.home.homeDirectory}/Downloads"
    "file://${config.home.homeDirectory}/Pictures"
    "file://${config.home.homeDirectory}/Projects"
  ];

  programs.opencode-config = {
    enable = true;

    opencodeGo.enable = false;
    opencodeZen.enable = false;

    extraConfig = privateConfig.opencodeConfig or { };

    profiles =
      lib.optionalAttrs ((privateConfig.workProfile or null) != null) {

        work = lib.recursiveUpdate privateConfig.workProfile {
          config.provider."local-llm" = {
            npm = "@ai-sdk/openai-compatible";
            name = "Local LLM (Ollama)";
            options = {
              baseURL = "http://localhost:11434/v1";
              apiKey = "ollama";
            };
            models = {
              "qwen2.5-coder:7b" = {
                name = "Qwen2.5 Coder 7B (local, fast code)";
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              "qwen2.5-coder:14b" = {
                name = "Qwen2.5 Coder 14B (local, strong code)";
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              "deepseek-coder-v2:16b" = {
                name = "DeepSeek Coder V2 16B (local, excellent code)";
                limit = {
                  context = 16384;
                  output = 8192;
                };
              };
              "deepseek-r1:8b" = {
                name = "DeepSeek R1 8B (local, reasoning)";
                limit = {
                  context = 16384;
                  output = 8192;
                };
              };
            };
          };
        };
      }
      // {

        personal = {
          scriptName = "ocp";

          mcpServers = [
            "nixos"
            "jobspy"
            "github"
            "playwright"
            "thunderbird"
          ];
          config = (import ./features/ai/opencode-personal.nix).config // {

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
              name = "Local LLM (Ollama)";
              options = {
                baseURL = "http://localhost:11434/v1";
                apiKey = "ollama";
              };
              models = {
                "qwen3:4b" = {
                  name = "Qwen3 4B (local, fast tool calling)";
                  limit = {
                    context = 32768;
                    output = 8192;
                  };
                };
                "qwen2.5:14b" = {
                  name = "Qwen2.5 14B (local, tool calling)";
                  limit = {
                    context = 32768;
                    output = 8192;
                  };
                };
                "qwen2.5-coder:7b" = {
                  name = "Qwen2.5 Coder 7B (local, fast code)";
                  limit = {
                    context = 32768;
                    output = 8192;
                  };
                };
                "qwen2.5-coder:14b" = {
                  name = "Qwen2.5 Coder 14B (local, strong code)";
                  limit = {
                    context = 32768;
                    output = 8192;
                  };
                };
                "deepseek-coder-v2:16b" = {
                  name = "DeepSeek Coder V2 16B (local, excellent code)";
                  limit = {
                    context = 16384;
                    output = 8192;
                  };
                };
                "deepseek-r1:8b" = {
                  name = "DeepSeek R1 8B (local, reasoning)";
                  limit = {
                    context = 16384;
                    output = 8192;
                  };
                };
              };
            };

            agent = (import ./features/ai/opencode-personal.nix).config.agent // {
              title.model = "opencode/big-pickle";
              summary.model = "opencode/big-pickle";
              compaction.model = "opencode/big-pickle";

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

            tools = {
              "github_*" = false;
              "playwright_*" = false;
            };
          };
        };

        groq = {
          scriptName = "ocg";

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

            provider."local-llm" = {
              npm = "@ai-sdk/openai-compatible";
              name = "Local LLM (Ollama)";
              options = {
                baseURL = "http://localhost:11434/v1";
                apiKey = "ollama";
              };
              models = {
                "qwen2.5-coder:7b" = {
                  name = "Qwen2.5 Coder 7B (local, fast code)";
                  limit = {
                    context = 32768;
                    output = 8192;
                  };
                };
                "qwen2.5-coder:14b" = {
                  name = "Qwen2.5 Coder 14B (local, strong code)";
                  limit = {
                    context = 32768;
                    output = 8192;
                  };
                };
                "deepseek-coder-v2:16b" = {
                  name = "DeepSeek Coder V2 16B (local, excellent code)";
                  limit = {
                    context = 16384;
                    output = 8192;
                  };
                };
                "deepseek-r1:8b" = {
                  name = "DeepSeek R1 8B (local, reasoning)";
                  limit = {
                    context = 16384;
                    output = 8192;
                  };
                };
              };
            };

            agent = {

              build.model = "groq/llama-3.3-70b-versatile";
              plan.model = "groq/llama-3.3-70b-versatile";
              oracle.model = "groq/llama-3.3-70b-versatile";
              metis.model = "groq/llama-3.3-70b-versatile";
              momus.model = "groq/llama-3.3-70b-versatile";

              explore.model = "groq/llama-3.1-8b-instant";
              general.model = "groq/llama-3.1-8b-instant";
              librarian.model = "groq/llama-3.1-8b-instant";
              prometheus.model = "groq/llama-3.1-8b-instant";

              compaction.model = "groq/llama-3.1-8b-instant";
              summary.model = "groq/llama-3.1-8b-instant";
              title.model = "groq/llama-3.1-8b-instant";
            };
          };
        };
      };

    dispatcher.contexts = {
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

    secretEnv = (privateConfig.workSecretEnv or { }) // {
      GROQ_API_KEY = "/run/secrets/groq-api-key";
    };

    skills = { };
    commands = {
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
        4. If user asks to fix issues, apply them directly
        </process>
      '';
    };
  };

  programs.jcode-config = {
    enable = true;

    opencodeGo.enable = false;
    opencodeZen.enable = false;

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
          mcpServers = [
            "nixos"
            "jobspy"
            "github"
            "playwright"
            "thunderbird"
          ];
          config = {
            provider = {
              default_provider = "opencode";
              default_model = "opencode/big-pickle";
            };
            providers = {
              "opencode-go" = {
                type = "openai-compatible";
                base_url = "https://opencode.ai/zen/go/v1";
                api_key_env = "OPENCODE_API_KEY";
                models = [
                  {
                    id = "deepseek-v4-pro";
                    name = "DeepSeek V4 Pro";
                  }
                  {
                    id = "deepseek-v4-flash";
                    name = "DeepSeek V4 Flash";
                  }
                  {
                    id = "kimi-k2.6";
                    name = "Kimi K2.6";
                  }
                ];
              };
              "opencode" = {
                type = "openai-compatible";
                base_url = "https://opencode.ai/zen/v1";
                api_key_env = "OPENCODE_API_KEY";
                models = [
                  {
                    id = "big-pickle";
                    name = "Big Pickle";
                  }
                ];
              };
              "local-llm" = {
                type = "openai-compatible";
                base_url = "http://localhost:11434/v1";
                api_key_env = "OLLAMA_API_KEY";
                models = [
                  {
                    id = "qwen3:4b";
                    name = "Qwen3 4B (local, fast tool calling)";
                    context_window = 32768;
                  }
                  {
                    id = "qwen2.5:14b";
                    name = "Qwen2.5 14B (local, tool calling)";
                    context_window = 32768;
                  }
                  {
                    id = "qwen2.5-coder:7b";
                    name = "Qwen2.5 Coder 7B (local, fast code)";
                    context_window = 32768;
                  }
                  {
                    id = "qwen2.5-coder:14b";
                    name = "Qwen2.5 Coder 14B (local, strong code)";
                    context_window = 32768;
                  }
                  {
                    id = "deepseek-coder-v2:16b";
                    name = "DeepSeek Coder V2 16B (local, excellent code)";
                    context_window = 16384;
                  }
                  {
                    id = "deepseek-r1:8b";
                    name = "DeepSeek R1 8B (local, reasoning)";
                    context_window = 16384;
                  }
                ];
              };
            };
          };
        };

        groq = {
          scriptName = "jcg";
          mcpServers = [
            "nixos"
          ];
          config = {
            provider = {
              default_provider = "groq";
              default_model = "groq/llama-3.3-70b-versatile";
            };
            providers = {
              "groq" = {
                type = "openai-compatible";
                base_url = "https://api.groq.com/openai/v1";
                api_key_env = "GROQ_API_KEY";
                models = [
                  {
                    id = "llama-3.3-70b-versatile";
                    name = "Llama 3.3 70B Versatile";
                  }
                  {
                    id = "llama-3.1-8b-instant";
                    name = "Llama 3.1 8B Instant";
                  }
                  {
                    id = "qwen3-32b";
                    name = "Qwen3 32B";
                  }
                  {
                    id = "gpt-oss-20b";
                    name = "GPT OSS 20B";
                  }
                ];
              };
            };
          };
        };
      };

    dispatcher.contexts = {
      personal = {
        scriptName = "jcp";
        apiKeyEnvVar = "OPENCODE_API_KEY";
      };
      "opencode-go" = {
        scriptName = "jcp";
        apiKeyEnvVar = "OPENCODE_API_KEY";
      };
      groq = {
        scriptName = "jcg";
        apiKeyEnvVar = "GROQ_API_KEY";
      };
    }
    // lib.optionalAttrs ((privateConfig.workProfile or null) != null) {
      work = {
        scriptName = "jcw";
        apiKeyEnvVar = privateConfig.workInferenceEnvVar;
      };
    };

    secretEnv = (privateConfig.workSecretEnv or { }) // {
      GROQ_API_KEY = "/run/secrets/groq-api-key";
    };
  };

  programs.claude-code-config.commands = {
    "review" = {
      description = "Run CodeRabbit AI review on uncommitted changes or against base branch";
      prompt = "Run `cr review --agent --type uncommitted` (or `cr review --agent --base <branch>` if --base flag given) and present findings as Critical/Warning/Info tiers. If user asks to fix issues, point them to the findings and suggest addressing each manually.";
    };
  };

  programs.claude-desktop-config.secretEnv = privateConfig.workSecretEnv or { };

  programs.ai-skills.opencodeProfiles = [
    "work"
    "personal"
    "groq"
  ];

  programs.ai-skills.jcodeProfiles = [
    "work"
    "personal"
    "groq"
  ];

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

    secretEnv =
      lib.removeAttrs
        (
          (privateConfig.workSecretEnv or { })
          // {
            GROQ_API_KEY = "/run/secrets/groq-api-key";
          }
        )
        [
          "ANTHROPIC_API_KEY"
          "NVIDIA_API_KEY"
          "OPENCODE_API_KEY"
        ];
  };

}
