{
  pkgs,
  lib,
  customPkgs ? {},
  isNixOnDroid ? false,
  ...
}:
let

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
    ./zellij.nix
    ./nushell.nix
    ./ssh.nix
    ./yazi.nix
    ./zathura.nix
    ./bottom.nix
    ./teams-calls-fetch.nix
  ];

  home.packages =
    with pkgs;

    [
      timr-tui
      basalt
      comma
      fd
      fzf
      jq
      nixfmt-rfc-style
      ouch
      pv
      ripgrep
      sqlite
      wget
      zip
      cursor-cli
    ]

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

      aider-chat
      llm
      claude-monitor
    ]

    ++ lib.optionals (isDesktop || isDarwin) [
      cursor-cli
      claude-code
    ]

    ++ lib.optionals (isLinux && !isAndroid) [
      deploy-rs
    ]
    ++ lib.optionals isDesktop [
      customPkgs.device-mount
      customPkgs.device-umount
    ]
    ++ lib.optionals (customPkgs ? teams-calls-fetcher) [
      customPkgs.teams-calls-fetcher
    ];
}
