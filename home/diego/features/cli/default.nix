{ pkgs, ... }: {
  imports = [
    ./bat.nix
    ./bottom.nix
    ./broot.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./git.nix
    ./helix.nix
    ./nushell.nix
    ./pfetch.nix
    ./ripgrep.nix
    ./starship.nix
    ./yazi.nix
    ./zellij.nix
    ./zoxide.nix
  ];
  home.packages = with pkgs; [
    comma # Install and run programs by sticking a , before them
    gping
    jq # JSON pretty printer and manipulator
    nixfmt
    pv
    stow
    wget
    yt-dlp
    zip
  ];

}
