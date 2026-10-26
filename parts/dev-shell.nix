{ config, inputs, lib, ... }:
{
  flake.devShells = lib.genAttrs config.systems (system: {
    default = inputs.nixpkgs.legacyPackages.${system}.callPackage ../shell.nix { };
  });
}
