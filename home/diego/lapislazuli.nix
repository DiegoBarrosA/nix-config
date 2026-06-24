{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./global
    ./features/cli
    ./features/ai/opencode.nix
    ./features/ai/ai-tools.nix
  ];

  # macOS-specific home directory
  home.homeDirectory = lib.mkForce "/Users/${config.home.username}";

  # OpenCode MCP configuration (managed by modules/home-manager/opencode-config.nix)
  # MCP servers are shared with Zed via programs.mcp-config
  # NOTE: mcp.nix not imported here — firefox-devedition not available on aarch64-darwin
  programs.mcp-config = {
    enable = true;
    obsidian.enable = true;
    mcpNixos.enable = true;
  };

  programs.opencode-config = {
    # Enable OpenCode Go and Zen providers
    opencodeGo.enable = true;
    opencodeZen.enable = true;

    # Provider config disabled - manage manually for employer-specific models
    provider.enable = false;
    plugins = (import ./features/ai/session-character-visualizer.nix) { inherit pkgs; };
  };

  programs.ai-skills.opencodeProfiles = [ ];

  # Obsidian configuration (managed by modules/home-manager/obsidian-config.nix)
  programs.obsidian-vault = {
    enable = true;
    vaultPath = "${config.home.homeDirectory}/Notes";
    settings = {
      vimMode = true;
      showLineNumber = true;
      showInlineTitle = false;
      alwaysUpdateLinks = true;
      newFileLocation = "folder";
      newFileFolderPath = "Quick notes";
      attachmentFolderPath = "Attachments";
      openBehavior = "daily";
    };
    appearance = {
      theme = "moonstone";
      accentColor = "#828282";
      baseFontSize = 26;
      showViewHeader = true;
      showRibbon = false;
    };
    communityPlugins = [
      "obsidian-excalidraw-plugin"
      "dataview"
      "templater-obsidian"
    ];
    restApi.enable = true;
    syncthing.enable = false; # Disable syncthing on this host if not needed
  };

  home.packages = with pkgs; [
    # opencode - now managed by programs.opencode-config
    cursor-cli
    mermaid-cli
    cava
    bitwarden-cli
    yt-dlp
    zstd
    ripgrep
    glow
    spec-kit
    quickshell
    wl-clipboard # Wayland clipboard

    csvlens # CSV viewer TUI
    oxker # Docker TUI
    slumber # HTTP client TUI
    trippy # Network diagnostic TUI
    termusic # Terminal music player

    eza # Modern ls
    duf # Modern df
    dust # Modern du
    procs # Modern ps
  ];

  colorscheme = {
    type = "material-darker";
    mode = "dark";
  };
}
