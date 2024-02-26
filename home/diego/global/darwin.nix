{ inputs, lib, pkgs, config, outputs, builtins, ... }:
let inherit (inputs.nix-colors) colorSchemes;
in {
  imports = [ inputs.nix-colors.homeManagerModule ];
  colorscheme = lib.mkDefault colorSchemes.spaceduck;
  home.file.".colorscheme".text = config.colorscheme.slug;
  home = {
    username = lib.mkDefault "diego";
    homeDirectory = "/Users/${config.home.username}";
    stateVersion = lib.mkDefault "22.11";

  };
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };
  launchd.enable = true;
  programs = {
    home-manager.enable = true;
    git.enable = true;
    gpg.enable = true;
  };
  targets.darwin.defaults = {
    NSGlobalDomain = {
      AppleLanguages = [ "en_US" "es_CL" ];
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = true;
      AppleTemperatureUnit = "Celsius";
    };
    com.apple.desktopservices = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    com.googlecode.iterm2.OpenTmuxWindowsIn = 2; # Tabs in the attaching window
  };

}
