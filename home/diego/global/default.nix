{
  inputs,
  lib,
  pkgs,
  config,
  isNixOnDroid ? false,
  ...
}:
let

  hasSystemd = pkgs.stdenv.isLinux && !(isNixOnDroid || pkgs.stdenv.hostPlatform.isAndroid or false);
in
{
  imports = [

  ];

  home.sessionVariables = {
    NIX_PATH = "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
  };

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

  home.packages =
    let
      specialisation = pkgs.writeShellScriptBin "specialisation" ''
        profiles="$HOME/.local/state/nix/profiles"
        current="$profiles/home-manager"
        base="$profiles/home-manager-base"
        current_home="$HOME/.local/state/home-manager/gcroots/current-home" # For NixOS

        if [ -d "$current_home/specialisation" ]; then
          echo >&2 "Using current-home gcroot"
          ln -sfT "$(readlink "$current_home")" "$base"
        elif [ -d "$current/specialisation" ]; then
          echo >&2 "Using current profile as base"
          ln -sfT "$(readlink "$current")" "$base"
        elif [ -d "$base/specialisation" ]; then
          echo >&2 "Using previously linked base profile"
        else
          echo >&2 "No suitable base config found. Try 'home-manager switch' or 'nixos-rebuild switch' again."
          exit 1
        fi

        if [ -z "$1" ] || [ "$1" = "list" ] || [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
          find "$base/specialisation" -type l -printf "%f\n"
          exit 0
        fi

        echo >&2 "Switching to ''${1} specialisation"
        if [ "$1" == "base"  ]; then
          "$base/activate"
        else
          "$base/specialisation/$1/activate"
        fi
      '';

      toggle-theme = pkgs.writeShellScriptBin "toggle-theme" ''
        theme="$1"
        if [ -z "$theme" ]; then
          current=$(jq -r '.mode' "$HOME/.colorscheme.json")
          if [ "$current" = "light" ]; then
            theme="dark"
          else
            theme="light"
          fi
        fi
        exec ${lib.getExe specialisation} "$theme"
      '';
    in
    [
      specialisation
      toggle-theme
    ];
}
