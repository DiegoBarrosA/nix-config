{ config, inputs, lib, ... }:
{
  flake.legacyPackages = lib.genAttrs config.systems (
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = builtins.attrValues config.flake.overlays;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        permittedInsecurePackages = [
          "olm-3.2.16"
          "pypy2.7-setuptools-44.0.0"
          "pypy2.7-pip-20.3.4"
        ];
      };
    }
  );
}
