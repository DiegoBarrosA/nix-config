{
  pkgs,
  lib,
  isNixOnDroid ? false,
  ...
}:
let
  # Platform detection. nix-on-droid (phone) passes `isNixOnDroid = true` via
  # home-manager.extraSpecialArgs; its pkgs are aarch64-linux, so
  # `hostPlatform.isAndroid` can't detect the phone by itself.
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isAndroid = isNixOnDroid || pkgs.stdenv.hostPlatform.isAndroid or false;
  isDesktop = isLinux && !isAndroid;
in
{
  imports = [
    ./zoxide.nix
    ./helix.nix
    ./pfetch.nix
    ./git.nix
    ./starship.nix
    ./fzf.nix
    ./bat.nix
    ./zellij.nix # Zellij multiplexer (manual material-darker theme)
    ./nushell.nix # Nushell with vi mode, Ctrl+T for Zellij
    ./ssh.nix # Multiple SSH keys with per-host selection, agent registration
    ./yazi.nix
    ./zathura.nix
    ./bottom.nix
  ];

  home.packages =
    with pkgs;
    # Core CLI tools (all platforms)
    [
      timr-tui
      basalt
      comma # Install and run programs by sticking a , before them
      fd # Better find
      fzf
      jq # JSON pretty printer and manipulator
      nixfmt-rfc-style
      ouch # TUI/CLI archive compress+decompress (tar/zip/7z/…); pairs with yazi
      pv
      ripgrep # Better grep
      sqlite # sqlite3 CLI — used by the netsuite-mcp Firefox cookie extraction
      wget
      zip
      cursor-cli
    ]
    # Linux/macOS desktop tools (not Android)
    ++ lib.optionals (isDesktop || isDarwin) [
      gh
      broot
      uv
      gping
      stow
      codex
      teleport
      scope-tui
      antigravity-cli

      # AI coding tools
      aider-chat # AI pair programming (works with Ollama)
      llm # Simon Willison's unified LLM CLI
      claude-monitor # Real-time Claude Code usage monitor
    ]
    # Desktop-only tools (Linux desktop or macOS, not servers/mobile)
    ++ lib.optionals (isDesktop || isDarwin) [
      cursor-cli
      claude-code
    ]
    # Deployment tools (only useful on systems that deploy to others)
    ++ lib.optionals (isLinux && !isAndroid) [
      deploy-rs
    ];
}
