{ config, lib, ... }: {

  programs.eza = {
    enable = true;
    enableAliases = true;
    extraOptions = [ "--group-directories-first" "--header" ];
  };

  programs.fish.shellAbbrs.ls = lib.mkIf config.programs.fish.enable
    "eza -al --color=always --group-directories-first";
}

