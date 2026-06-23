{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  # Detect if we're on a systemd-based system (Linux, but not Android/nix-on-droid)
  hasSystemd = pkgs.stdenv.isLinux && !pkgs.stdenv.hostPlatform.isAndroid;
in
{
  imports = [
    # modules are provided centrally via flake `homeManagerModules`
  ];
  # merged into home.file block below
  # Essential for non-NixOS systems to ensure packages are in PATH
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

  # Only enable systemd user services on Linux with systemd (not Android)
  systemd.user.startServices = lib.mkIf hasSystemd "sd-switch";

  # GPG agent only on systems with systemd
  services.gpg-agent.enable = lib.mkIf hasSystemd false;

  home = {
    username = lib.mkDefault "diego";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      NH_FLAKE = "$HOME/Documents/NixConfig";
      # Disable libadwaita animations (may help with some styling)
      ADW_DISABLE_PORTAL = "1";
    };

  };

  # Specialisations for light/dark
  specialisation = {
    dark.configuration = {
      colorscheme.type = lib.mkOverride 1498 "gruvbox-dark-medium";
      colorscheme.mode = lib.mkOverride 1498 "dark";
    };
    light.configuration = {
      colorscheme.type = lib.mkOverride 1498 "gruvbox-light-medium";
      colorscheme.mode = lib.mkOverride 1498 "light";
    };
  };

  # Write current colorscheme to a file
  home.file = {
    ".colorscheme.json".text = builtins.toJSON config.colorscheme;
    ".colorscheme".text = config.colorscheme.type;
  };

  # Add specialisation and toggle-theme to home.packages
  home.packages =
    let
      specialisation = pkgs.writeShellScriptBin "specialisation" ''
        profiles="$HOME/.local/state/nix/profiles"
        current="$profiles/home-manager"
        base="$profiles/home-manager-base"
        current_home="$HOME/.local/state/home-manager/gcroots/current-home" # For NixOS

        # Try to get it from NixOS, if so, link it
        if [ -d "$current_home/specialisation" ]; then
          echo >&2 "Using current-home gcroot"
          ln -sfT "$(readlink "$current_home")" "$base"
        # If current contains specialisations, link it as base
        elif [ -d "$current/specialisation" ]; then
          echo >&2 "Using current profile as base"
          ln -sfT "$(readlink "$current")" "$base"
        # Check that $base contains specialisations before proceeding
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
        # Determine hostname from various sources
        hostname="''${HOSTNAME:-$(hostname -s 2>/dev/null || cat /etc/hostname 2>/dev/null || echo unknown)}"
        ${lib.getExe pkgs.home-manager} --flake "$HOME/Documents/Repositories/nix-config#${config.home.username}@$hostname" --specialisation "$theme" switch
      '';
    in
    [
      specialisation
      toggle-theme
    ];
}
