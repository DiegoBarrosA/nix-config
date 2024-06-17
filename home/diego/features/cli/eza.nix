{ config, lib, ... }: {
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    extraOptions = [ "--group-directories-first" "--header" ];
  };
}

