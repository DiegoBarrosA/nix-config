{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.vscode-custom;

  # Official AI agent extensions, fetched declaratively from OpenVSX
  # (open-vsx.org) rather than the MS marketplace — OpenVSX is redistributable
  # and reachable without accepting Microsoft's marketplace ToS.
  #
  # We build these with buildVscodeMarketplaceExtension + an explicit fetchurl
  # src (instead of extensionsFromVscodeMarketplace) for two reasons:
  #   1. The claude-code VSIX filename contains an '@' (platform tag) which is
  #      an illegal Nix store-path character; an explicit `name` sidesteps it.
  #   2. claude-code is platform-specific — we must pin the linux-x64 build.
  #
  # Version + sha256 are pinned manually; `nix flake update` will NOT bump
  # these. To upgrade: change the version, then update the sha256
  # (nix-prefetch-url the new VSIX, use --name to avoid the '@' error).

  opencodeExtension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "sst-dev";
      name = "opencode";
      version = "0.0.13";
    };
    vsix = pkgs.fetchurl {
      name = "sst-dev-opencode-0.0.13.vsix";
      url = "https://open-vsx.org/api/sst-dev/opencode/0.0.13/file/sst-dev.opencode-0.0.13.vsix";
      sha256 = "1m301j2qbym3j2qnck76jyxakca3h1qiybc2r7wy7z11m98mg9z9";
    };
    meta = {
      description = "Official opencode VS Code extension";
      license = lib.licenses.mit;
    };
  };

  claudeCodeExtension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "anthropic";
      name = "claude-code";
      version = "2.1.207";
    };
    vsix = pkgs.fetchurl {
      name = "anthropic-claude-code-2.1.207-linux-x64.vsix";
      url = "https://open-vsx.org/api/Anthropic/claude-code/linux-x64/2.1.207/file/Anthropic.claude-code-2.1.207@linux-x64.vsix";
      sha256 = "1ckmrnq0i8rsr9ifwq0dccwgfnz076ahs9mlnkl2wc0sx3m5l5j3";
    };
    meta = {
      description = "Claude Code for VS Code (linux-x64)";
      license = lib.licenses.unfree;
    };
  };
in
{
  options.programs.vscode-custom = {
    enable = lib.mkEnableOption "VSCode with official AI agent extensions (Claude Code + opencode), Stylix-themed";
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      # HM fully owns the extension set (declarative). Stylix's vscode target
      # appends its own `stylix.stylix` theme extension to this same profile —
      # HM merges the two extension lists, so there's no conflict.
      mutableExtensionsDir = false;

      profiles.default = {
        extensions = [
          claudeCodeExtension
          opencodeExtension
        ];

        # Sane defaults only. Deliberately DO NOT set `workbench.colorTheme`
        # or any font family/size keys here: stylix.targets.vscode owns those
        # (it sets colorTheme = "Stylix" plus fonts from stylix.fonts).
        # settings.json deep-merges, so ours combine with Stylix's cleanly.
        userSettings = {
          "telemetry.telemetryLevel" = "off";
          # HM owns extensions; stop VSCode fighting it with auto-updates.
          "update.mode" = "none";
          "extensions.autoCheckUpdates" = false;
          "extensions.autoUpdate" = false;
          "editor.formatOnSave" = true;
          "files.trimTrailingWhitespace" = true;
          "files.insertFinalNewline" = true;
          "editor.minimap.enabled" = false;
          "workbench.startupEditor" = "none";
        };
      };
    };
  };
}
