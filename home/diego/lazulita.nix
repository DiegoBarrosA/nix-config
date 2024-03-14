{ inputs, pkgs, ... }: {
  imports = [
    ./features/cli
    ./features/desktop/common/alacritty.nix
    ./global/darwin.nix
    ./features/desktop/common/firefox
    ./features/emacs
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
    vscodium
  ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
