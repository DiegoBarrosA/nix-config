{ inputs, pkgs, ... }: {
  imports = [
    ./global
    ./features/desktop/sway
    ./features/cli
    ./features/wireless
    ./features/emacs
  ];

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin;
}
