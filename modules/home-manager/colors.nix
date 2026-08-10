{ lib,
  config,
  pkgs,
  nix-colors,
  ...
}: let
  cfg = config.colorscheme;
  inherit (lib) types mkOption;

  hexColor = types.strMatching "#([0-9a-fA-F]{3}){1,2}";

  # Palettes defined in this repo, checked before the nix-colors set so a local
  # scheme can also shadow an upstream one of the same name.
  localSchemes = import ./colorschemes;
in {
  options.colorscheme = {
    mode = mkOption {
      type = types.enum ["dark" "light"];
      default = "dark";
    };
    type = mkOption {
      type = types.str;
      default = "material-darker";
    };

    # Papirus ships one folder icon set per colour and Stylix does not theme
    # icons, so the pairing has to be stated alongside the scheme.
    iconFolderColor = mkOption {
      type = types.str;
      default = "indigo";
      description = "Papirus folder colour to pair with this scheme.";
      example = "grey";
    };

    colors = mkOption {
      readOnly = true;
      type = types.attrs;
      default =
        localSchemes.${cfg.type} or nix-colors.colorSchemes.${cfg.type}.palette or {};
    };

    # type/mode pairs applied by the "dark" and "light" home-manager
    # specialisations (wired up in home/diego/global/default.nix). Defaults
    # preserve the original gruvbox toggle; a host with its own palette
    # (e.g. a monochrome scheme) should override both entries so `type` and
    # `mode` switch together instead of drifting apart.
    specialisations = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            type = mkOption {
              type = types.str;
              description = "colorscheme.type to apply for this specialisation.";
            };
            mode = mkOption {
              type = types.enum [ "dark" "light" ];
              description = "colorscheme.mode to apply for this specialisation.";
            };
          };
        }
      );
      default = {
        dark = {
          type = "gruvbox-dark-medium";
          mode = "dark";
        };
        light = {
          type = "gruvbox-light-medium";
          mode = "light";
        };
      };
      description = "colorscheme type/mode pairs applied by the light/dark home-manager specialisations.";
    };

    # Gives access to other homes' colors
    # hosts = mkOption {
    #   readOnly = true;
    #   type = types.attrs;
    #   default = let
    #     homeConfigs = lib.mapAttrs' (n: v: lib.nameValuePair (lib.last (lib.splitString "@" n)) v.config) outputs.homeConfigurations;
    #     nixosConfigs = lib.mapAttrs (_: v: v.config.home-manager.users.diego) outputs.nixosConfigurations;
    #   in 
    #     lib.mapAttrs (_: v: v.colorscheme.rawColorscheme.colors) (homeConfigs // nixosConfigs);
    # };
  };
}
