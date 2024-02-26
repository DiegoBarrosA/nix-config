{ inputs, lib, pkgs, config, outputs, ... }:
let inherit (inputs.nix-colors) colorSchemes;
in {
  imports = [ inputs.nix-colors.homeManagerModule ../features/emacs ];
  colorscheme = lib.mkDefault colorSchemes.spaceduck;
  home.file.".colorscheme".text = config.colorscheme.slug;
  home = {
    username = lib.mkDefault "diego";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
  };
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };
  programs = {
    home-manager.enable = true;
    git.enable = true;
    gpg.enable = true;
  };
  systemd.user.startServices = "sd-switch";
  services.gpg-agent.enable = true;
}
