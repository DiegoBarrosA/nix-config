{ config, inputs, ... }:
{
  flake.nixosConfigurations.cobalto = inputs.nixpkgs.lib.nixosSystem {
    pkgs = config.flake.legacyPackages.x86_64-linux;
    modules = with config.flake.modules.nixos; [
      cobalto
      openrgb
    ];
    specialArgs = {
      inherit inputs;
      self = inputs.self;
      outputs = inputs.self;
      customPkgs = config.flake.packages.x86_64-linux;
      desktop = null;
      theme = {
        scheme = "material-darker";
        mode = "dark";
      };
    };
  };
}
