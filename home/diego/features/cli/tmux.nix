{ config, pkgs, ... }: {
  programs.fish.shellInit = "${pkgs.tmux}/bin/tmux";
  programs.tmux = {
    enable = true;
    shell = "\${pkgs.fish}/bin/fish";
    clock24 = true;
    keyMode = "vi";

  };
}
