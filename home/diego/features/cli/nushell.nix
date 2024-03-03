{ config, pkgs, ... }: {
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "hx";
      top = "btm";
    };
    extraEnv = ''
      mkdir ~/.cache/starship
      ${pkgs.starship}/bin/starship init nu | save -f ~/.cache/starship/init.nu
    '';
    extraConfig = ''
          use ~/.cache/starship/init.nu
           $env.config = {
        edit_mode: emacs
      }

    '';
  };
}
