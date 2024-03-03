{ inputs, pkgs, ... }: {
  imports = [
    ./features/cli
    ./features/desktop/common/alacritty.nix
    ./global/darwin.nix
    ./features/desktop/common/firefox
  ];
  home.packages = with pkgs; [
    keka
    reaper
    rustup
    airwindows-lv2
    openssl
    inkscape
    zstd
  ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
