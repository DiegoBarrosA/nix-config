{
  config,
  lib,
  pkgs,
  privateConfig ? { },
  ...
}:
let
  cfg = config.programs.zed-editor-custom;

  # Build language model providers from privateConfig and standard providers
  # Handle both full privateConfig and opencodeConfig-only variants
  nvidiaModels =
    let
      opencodeCfg = privateConfig.opencodeConfig or privateConfig;
    in
    opencodeCfg.provider."nvidia-inference".models or { };

  nvidiaBaseUrl =
    let
      opencodeCfg = privateConfig.opencodeConfig or privateConfig;
    in
    opencodeCfg.provider."nvidia-inference".options.baseURL or null;

  languageModels = {
    # DeepSeek built-in provider
    deepseek = {
      api_url = "https://api.deepseek.com/v1";
    };

    # NVIDIA Inference API via openai_compatible (only present when private-config supplies the URL)
    openai_compatible = lib.optionalAttrs (nvidiaBaseUrl != null && nvidiaModels != { }) {
      "NVIDIA" = {
        api_url = nvidiaBaseUrl;
        available_models = lib.mapAttrsToList (modelId: modelCfg: {
          name = modelId;
          display_name = modelCfg.name or modelId;
          max_tokens = modelCfg.options.max_tokens or 8192;
        }) nvidiaModels;
      };
    } // {
      "OpenCode Go" = {
        api_url = "https://opencode.ai/zen/go/v1";
        available_models = [
          { name = "deepseek-v4-flash"; display_name = "DeepSeek V4 Flash (Go)"; max_tokens = 8192; }
          { name = "qwen3.5-plus"; display_name = "Qwen 3.5 Plus (Go)"; max_tokens = 8192; }
          { name = "minimax-m2.5"; display_name = "MiniMax M2.5 (Go)"; max_tokens = 8192; }
          { name = "deepseek-v4-pro"; display_name = "DeepSeek V4 Pro (Go)"; max_tokens = 8192; }
          { name = "glm-5.1"; display_name = "GLM 5.1 (Go)"; max_tokens = 8192; }
          { name = "kimi-k2.6"; display_name = "Kimi K2.6 (Go)"; max_tokens = 8192; }
          { name = "mimo-v2.5-pro"; display_name = "MiMo V2.5 Pro (Go)"; max_tokens = 8192; }
          { name = "qwen3.6-plus"; display_name = "Qwen 3.6 Plus (Go)"; max_tokens = 8192; }
        ];
      };

      "OpenCode Zen" = {
        api_url = "https://opencode.ai/zen/v1";
        available_models = [
          { name = "deepseek-v4-flash-free"; display_name = "DeepSeek V4 Flash Free (Zen)"; max_tokens = 8192; }
          { name = "minimax-m2.5-free"; display_name = "MiniMax M2.5 Free (Zen)"; max_tokens = 8192; }
          { name = "gpt-5-nano"; display_name = "GPT 5 Nano (Zen)"; max_tokens = 8192; }
          { name = "claude-haiku-4-5"; display_name = "Claude Haiku 4.5 (Zen)"; max_tokens = 8192; }
          { name = "claude-sonnet-4-5"; display_name = "Claude Sonnet 4.5 (Zen)"; max_tokens = 8192; }
          { name = "claude-opus-4-5"; display_name = "Claude Opus 4.5 (Zen)"; max_tokens = 8192; }
        ];
      };
    };
  };

  # Base user settings (theme and fonts managed by stylix)
  baseSettings = {
    "tab_size" = 2;
    "hard_tabs" = false;
    "scrollbar" = {
      show = "auto";
    };
    "relative_line_numbers" = false;
    "indent_guides" = {
      enabled = true;
      coloring = "fixed";
      line_width = 1;
    };
    "telemetry" = {
      diagnostics = false;
      metrics = false;
    };
    "format_on_save" = "on";
    "remove_trailing_whitespace_on_save" = true;
    "ensure_final_newline_on_save" = true;
    "autosave" = "off";
    "show_inline_completions" = true;
    "agent" = {
      "default_profile" = "agent";
      "always_allow_tool_actions" = false;
    };
    "language_models" = languageModels;
  };

  # Keymap settings - vim mode since user uses vim everywhere
  keymaps = {
    vim_mode = true;
  };
in
{
  options.programs.zed-editor-custom = {
    enable = lib.mkEnableOption "Zed editor with MCP and LLM provider configuration";

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to integrate MCP servers from programs.mcp.servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      defaultEditor = false;
      enableMcpIntegration = cfg.enableMcpIntegration;

      extensions = [
        "base16"
        "nix"
        "rust"
        "typescript"
        "toml"
        "git-firefly"
        "tailwind"
        "docker-compose"
        "sql"
        "markdown"
        "proto"
        "elixir"
        "go"
        "python"
        "bash"
      ];

      userSettings = baseSettings // {
        vim_mode = true;
      };

      userKeymaps = [
        {
          context = "Editor && vim_mode == normal && !VimWaiting && !menu";
          bindings = {
            "space space" = "file_finder::Toggle";
            "space f f" = "file_finder::Toggle";
            "space f g" = "pane::DeploySearch";
            "space g g" = "git::Git";
            "space b d" = "pane::CloseActiveItem";
            "space w s" = "workspace::Save";
            "space w q" = "workspace::CloseWindow";
            "space t t" = "terminal_panel::ToggleFocus";
            "space c a" = "agent::ToggleFocus";
          };
        }
        {
          context = "Editor && vim_mode == insert";
          bindings = {
            "ctrl-j" = "editor::ShowSignatureHelp";
          };
        }
      ];

      # Must be a list: home-manager merges tasks.json with jq as arrays ($dynamic + $static).
      userTasks = [
        {
          label = "nix build";
          command = "nix";
          args = [ "build" ".#\${ZED_CUSTOM_RUST_PACKAGE}" ];
          cwd = "\${ZED_WORKTREE_ROOT}";
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "never";
          shell = "system";
        }
        {
          label = "nix flake update";
          command = "nix";
          args = [ "flake" "update" ];
          cwd = "\${ZED_WORKTREE_ROOT}";
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "never";
          shell = "system";
        }
        {
          label = "nix fmt";
          command = "nix";
          args = [ "fmt" ];
          cwd = "\${ZED_WORKTREE_ROOT}";
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "on_success";
          shell = "system";
        }
      ];
    };
  };
}
