{ inputs, pkgs, ... }: 
{
  imports = [
    ./global
    #./features/cli
    ./features/cli/fish.nix
    ./features/cli/starship.nix
    ./features/cli/zoxide.nix
    ./features/cli/git.nix
    ./features/emacs
  ];
  home.packages = [ pkgs.cascadia-code ];
  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
