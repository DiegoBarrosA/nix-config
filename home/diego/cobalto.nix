{ inputs, pkgs, ... }: {
  imports = [
    ./global
    ./features/desktop/sway
    ./features/cli
    ./features/cli/optional/onedrive.nix
    ./features/gaming/obs.nix
   ./features/gaming/steam.nix
    ./features/gaming/prism-launcher.nix
    ./features/desktop/other/zoom.nix
  # ./features/desktop/other/prodaudio.nix

  ];

  colorscheme = inputs.nix-colors.colorSchemes.material-darker;
}
