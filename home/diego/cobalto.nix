{ inputs, ... }: {
  imports = [
    ./global
    ./features/cli
    #./features/proaudio
    ./features/desktop/sway
  ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
