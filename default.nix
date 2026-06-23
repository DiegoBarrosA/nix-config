{...}:
let
  flake = (builtins.getFlake "/home/diego/Repos/nix-config");
in flake.deploy