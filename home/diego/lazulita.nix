{ inputs, pkgs, ... }: {
  imports = [
    ./features/cli
    ./features/desktop/common/alacritty.nix
    #    ./features/emacs
    ./global/darwin.nix
    ./features/desktop/common/firefox
    ./features/desktop/common/mpv.nix
  ];
  home.packages = with pkgs; [
    keka
    reaper
    rustup
    airwindows-lv2
    openssl
    inkscape
    zstd
    ripgrep
    findutils
    fd
  ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
