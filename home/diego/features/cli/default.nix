{ pkgs, ... }: {
  imports = [
    ./zellij.nix
    ./zoxide.nix
    ./helix.nix
    ./pfetch.nix
    ./git.nix
    ./starship.nix
    ./fzf.nix
    ./bat.nix
    ./nushell.nix
    ./yazi.nix
    ./bottom.nix
    ./carapace.nix
  ];
  home.packages = with pkgs; [
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
