# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ pkgs }: {
  plymouth-themes = pkgs.callPackage ./plymouth-themes { };
  lyrics = pkgs.callPackage ./lyrics { };
  #  swayshot = pkgs.callPackage ./sway-interactive-screenshot{ };
}
