{ lib,
  config,
  pkgs,
  nix-colors,
  ...
}: let
  cfg = config.colorscheme;
  inherit (lib) types mkOption;

  hexColor = types.strMatching "#([0-9a-fA-F]{3}){1,2}";
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

    colors = mkOption {
      readOnly = true;
      type = types.attrs;
      default = nix-colors.colorSchemes.${cfg.type}.palette or {};
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
