{ config, lib, ... }:

let cfg = config.programs.swaylock;
in {
  disabledModules = [ "programs/swaylock.nix" ];

  options.programs.swaylock = {
    enable = lib.mkEnableOption "swaylock";
    settings = lib.mkOption {
      type = with lib.types; attrsOf (oneOf [ bool float int str ]);
      default = { };
      description = ''
        Default arguments to <command>swaylock</command>. An empty set
        disables configuration generation.
      '';
      example = {
        color = "808080";
        font-size = 24;
        indicator-idle-visible = false;
        indicator-radius = 100;
        line-color = "ffffff";
        show-failed-attempts = true;
      };
    };
  };

  config.xdg.configFile."swaylock/config" = lib.mkIf cfg.enable {
    text = lib.concatStrings (lib.mapAttrsToList (n: v:
      if v == false then
        ""
      else
        (if v == true then n else n + "=" + builtins.toString v) + "\n")
      cfg.settings);
  };
}
