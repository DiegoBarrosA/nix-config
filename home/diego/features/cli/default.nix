{ pkgs, ... }: {
  imports = [
    ./zellij.nix
    ./eza.nix
    ./zoxide.nix
    ./helix.nix
    ./vim.nix
    ./pfetch.nix
    ./fish.nix
    ./git.nix
    ./starship.nix
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
