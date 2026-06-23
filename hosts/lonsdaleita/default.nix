# Nix-on-Droid configuration for lonsdaleita (Android phone)
{ config, lib, pkgs, inputs, customPkgs, ... }:

let
  # Import home-manager modules from the flake
  homeManagerModules = import ../../modules/home-manager;
in
{
  # System packages available in the nix-on-droid environment
  environment.packages = with pkgs; [
    # Essential tools
    vim
    git
    openssh
    curl
    wget

    # Common utilities
    procps
    findutils
    diffutils
    gnugrep
    gnused
    gnutar
    gzip
    zip
    unzip

    # Development
    jq
  ];

  # Backup etc files instead of failing to activate generation
  environment.etcBackupExtension = ".bak";

  # Enable flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Timezone
  time.timeZone = "America/Santiago";

  # Android integration
  android-integration = {
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
  };

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # Home-manager integration
  home-manager = {
    config = ../../home/diego/lonsdaleita.nix;
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    # Include custom home-manager modules (colors, fonts, etc.)
    sharedModules = builtins.attrValues homeManagerModules;
    extraSpecialArgs = {
      inherit inputs customPkgs;
      inherit (inputs) nix-colors;
    };
  };
}
