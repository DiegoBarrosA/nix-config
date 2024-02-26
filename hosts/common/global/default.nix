# This file (and the global directory) holds config that i use on all hosts
{ lib, inputs, outputs, ... }: {
  imports = [ ./openssh.nix ./fish.nix ./locale.nix ./sops.nix ];
  networking.domain = "minerales.network";
  environment = {
    loginShellInit = ''
      # Activate home-manager environment, if not already
      [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
    '';
    # Add terminfo files
    enableAllTerminfo = true;
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
