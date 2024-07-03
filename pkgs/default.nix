# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ pkgs }: {
  plymouth-themes = pkgs.callPackage ./plymouth-themes { };
  lyrics = pkgs.callPackage ./lyrics { };
  plymouth-spinner-monochrome =
    pkgs.callPackage ./plymouth-spinner-monochrome { };
  renoise-latest = pkgs.callPackage ./renoise { };
}
