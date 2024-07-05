{ inputs, ... }: {
  imports = [ ./global ./features/cli ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
