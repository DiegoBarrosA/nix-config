{
  inputs,
  self,
  legacyPackages,
  packages,
  homeModules,
  nixosModules,
}:
rec {
  mkHost =
    system: hostname: hostArgs:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = legacyPackages.${system};
      modules = [ "${self}/hosts/${hostname}" ] ++ (builtins.attrValues nixosModules);
      specialArgs = {
        inherit inputs self;
        outputs = self;
        customPkgs = packages.${system};
        desktop = hostArgs.desktop or null;
      };
    };

  mkHome =
    system: entrypoint: extraModules:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = legacyPackages.${system};
      extraSpecialArgs = {
        inherit inputs;
        inherit (inputs) nix-colors;
        customPkgs = packages.${system};
        privateConfig = inputs.private-config or { };
      };
      modules =
        (builtins.attrValues homeModules)
        ++ [
          inputs.stylix.homeModules.stylix
          inputs.private-config.homeManagerModules.workMcpConfig
          entrypoint
        ]
        ++ extraModules;
    };
}
