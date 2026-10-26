{ config, inputs, lib, ... }:
{
  flake.apps = lib.genAttrs config.systems (
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      deploy-rs = inputs.deploy-rs.packages.${system}.deploy-rs;
    in
    {
      deploy = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "deploy" ''
            exec ${deploy-rs}/bin/deploy --skip-checks "$@"
          ''
        );
        meta = {
          description = "Deploy NixOS configurations to remote hosts";
        };
      };
    }
  );
}
