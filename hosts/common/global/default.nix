# This file (and the global directory) holds config that i use on all hosts
{ inputs, outputs, customPkgs ? {}, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./openssh.nix
    ./locale.nix
  ];
  networking.domain = "mineral.network";

  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs customPkgs;
    inherit (inputs) nix-colors;
    privateConfig = inputs.private-config or { };
  };
  environment = {
    loginShellInit = ''
      # Activate home-manager environment, if not already
      [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
    '';
    # Not using enableAllTerminfo - pulls in termite which has broken vte build
    # in pinned nixpkgs. Common terminals provide their own terminfo via packages.
  };
  # Allows users to allow others on their binds
  programs.fuse.userAllowOther = true;
  hardware.enableRedistributableFirmware = true;
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];
}
