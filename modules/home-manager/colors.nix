{ lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.colorscheme;
  inherit (lib) types mkOption;

  hexColor = types.strMatching "#([0-9a-fA-F]{3}){1,2}";

  localSchemes = import ./colorschemes;

  stylixBase16 = inputs.stylix.inputs.base16.lib { inherit pkgs lib; };
  tintedSchemes = inputs.stylix.inputs.tinted-schemes;
  schemeBySlug = slug: stylixBase16.mkSchemeAttrs (tintedSchemes + "/base16/${slug}.yaml");
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
        localSchemes.${cfg.type} or (schemeBySlug cfg.type);
    };

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

  };
}
