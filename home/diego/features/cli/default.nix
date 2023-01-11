{ pkgs, ... }: {
  imports = [ ./fish.nix ./git.nix ./starship.nix ./mpd.nix ./ncmpcpp.nix ];
  home.packages = with pkgs; [
    bottom # System viewer
    comma # Install and run programs by sticking a , before them
    distrobox # Nice escape hatch, integrates docker images with my environment
    exa # Better ls
    fd # Better find
    gping
    jq # JSON pretty printer and manipulator
    nixfmt # Nix formatter
    pv
    ripgrep # Better grep
    stow
    wget
    yt-dlp
    zip
    zoxide
  ];
}
