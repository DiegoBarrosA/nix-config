{ pkgs, ... }: {
  imports = [
    ./zellij.nix
    ./zoxide.nix
    ./helix.nix
    ./vim.nix
    ./pfetch.nix
    ./fish.nix
    ./eza.nix
    ./git.nix
    ./starship.nix
    ./fzf.nix
    ./bat.nix
  ];
  home.packages = with pkgs; [
    bottom # System viewer
    comma # Install and run programs by sticking a , before them
    fd # Better find
    gping
    jq # JSON pretty printer and manipulator
    nixfmt
    pv
    ripgrep # Better grep
    stow
    wget
    yt-dlp
    zip
  ];

}
