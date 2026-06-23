# Home-manager configuration for lonsdaleita (nix-on-droid Android)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Global config is now cross-platform compatible (systemd options are guarded)
    ./global
    # Import CLI features (shared across all hosts)
    ./features/cli
  ];

  # Override home settings for nix-on-droid
  # nix-on-droid uses /data/data/com.termux.nix/files/home
  home = {
    username = lib.mkForce "nix-on-droid";
    homeDirectory = lib.mkForce "/data/data/com.termux.nix/files/home";
    stateVersion = lib.mkForce "24.05";
  };

  # Colorscheme
  colorscheme = {
    type = "material-darker";
    mode = "dark";
  };

  # Additional packages for mobile use
  # Note: Some packages from features/cli/default.nix may not be ideal for mobile
  # but platform guards there will filter them out
  home.packages = with pkgs; [
    # Mobile-friendly TUI apps
    yt-dlp # Download videos
    bitwarden-cli # Password management
    zstd # Compression
    glow # Markdown viewer

    # Modern CLI replacements
    eza # Modern ls
    duf # Modern df
    dust # Modern du
    procs # Modern ps

    # Utilities
    mermaid-cli # Diagrams
  ];
}
