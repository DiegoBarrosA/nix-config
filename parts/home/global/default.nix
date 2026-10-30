{ ... }:
{
  flake.modules.homeManager.global =
{
  inputs,
  lib,
  pkgs,
  config,
  isNixOnDroid ? false,
  ...
}:
let

  hasSystemd = pkgs.stdenv.hostPlatform.isLinux && !(isNixOnDroid || pkgs.stdenv.hostPlatform.isAndroid or false);
in
{
  imports = [

  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };
  programs = {
    home-manager.enable = true;
    git.enable = true;

    gpg.enable = true;
  };

  systemd.user.startServices = lib.mkIf hasSystemd "sd-switch";

  services.gpg-agent.enable = lib.mkIf hasSystemd false;

  home = {
    username = lib.mkDefault "diego";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      NIX_PATH = "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
      NH_FLAKE = "$HOME/Projects/Personal/nix/nix-config";

      ADW_DISABLE_PORTAL = "1";
    };

  };

  specialisation = lib.mapAttrs (_name: sc: {
    configuration = {
      colorscheme.type = lib.mkForce sc.type;
      colorscheme.mode = lib.mkForce sc.mode;
    };
  }) config.colorscheme.specialisations;

  home.file = {
    ".colorscheme.json".text = builtins.toJSON config.colorscheme;
    ".colorscheme".text = config.colorscheme.type;
  };
};
}
