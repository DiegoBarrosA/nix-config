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
    system: entrypoint: extraModules: { desktop ? null }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = legacyPackages.${system};
      extraSpecialArgs = {
        inherit inputs;
        inherit (inputs) nix-colors;
        customPkgs = packages.${system};
        privateConfig = inputs.private-config or { };
        inherit desktop;
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

  # Nix-on-Droid is its own module system (not NixOS), so this is a
  # parallel output to mkHost/mkHome. The phone builds the profile on-device
  # with `nix-on-droid switch --flake .#infinix` (aarch64-linux only).
  # `home-manager-path` must point at the repo's (unstable) home-manager input:
  # nix-on-droid's pinned 24.05 home-manager references `pkgs.pinentry`, which
  # was removed from current nixpkgs and breaks evaluation.
  mkNixOnDroid =
    hostname:
    inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = legacyPackages.aarch64-linux;
      modules = [ "${self}/hosts/${hostname}/nix-on-droid.nix" ];
      home-manager-path = inputs.home-manager.outPath;
      extraSpecialArgs = {
        inherit inputs;
        inherit (inputs) nix-colors;
      };
    };
}
