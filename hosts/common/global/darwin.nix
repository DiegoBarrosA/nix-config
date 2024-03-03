# This file (and the global directory) holds config that i use on all hosts
{ lib, inputs, outputs, pkgs, config, ... }: {
  imports = [ inputs.home-manager.darwinModules.home-manager ];
  environment = {
    loginShell = pkgs.nushell;
    # pathsToLink = [ "/share/zsh" ];
  };
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };
  };

  nix = {
    settings = {
      trusted-users = [ "diego" "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
    package = pkgs.nix;
    gc = { automatic = true; };

    # Add each flake input as a registry
    # To make nix3 commands consistent with the flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Map registries to channels
    # Very useful when using legacy commands
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
      config.nix.registry;
  };
  # Allows users to allow others on their binds
  system.stateVersion = lib.mkDefault 4;
}
