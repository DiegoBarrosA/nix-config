{ inputs, pkgs, ... }: {
  imports = [
    ./global
    ./features/cli

  ];
  home.packages = [ pkgs.cascadia-code ];
}
