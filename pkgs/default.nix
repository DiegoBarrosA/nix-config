# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ pkgs, lib ? null, colors ? null, privatePackages ? {}, ... }:

let
  iso639-lang = pkgs.python3Packages.callPackage ./iso639-lang { };
in
{
  inherit iso639-lang;
  lyrics = pkgs.callPackage ./lyrics { };
  lazylibrarian = pkgs.callPackage ./lazylibrarian { inherit iso639-lang; };
  thunderbird-mcp = pkgs.callPackage ./thunderbird-mcp { };
  codex-acp = pkgs.callPackage ./codex-acp { };
  claude-desktop = pkgs.callPackage ./claude-desktop { };
  jcode = pkgs.callPackage ./jcode { };
} // privatePackages
