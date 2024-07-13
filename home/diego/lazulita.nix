{ inputs, pkgs, ... }: {
  imports = [
    ./features/cli
    ./features/desktop/common/alacritty.nix
    ./global/darwin.nix
    ./features/desktop/common/firefox
    ./features/desktop/common/mpv.nix
  ];
  home.packages = with pkgs; [
    keka
    rustup
    openssl
    inkscape
    zstd
    ripgrep
    findutils
    fd
    ffmpeg
  ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
