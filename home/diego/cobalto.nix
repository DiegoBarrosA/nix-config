{ inputs, kgs, ... }: {
  imports = [
    ./global
    ./features/desktop/sway
    ./features/cli
    ./features/cli/optional/ncmpcpp.nix
    ./features/gaming/obs.nix
    ./features/gaming

  ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
