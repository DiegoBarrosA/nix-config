# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ pkgs, lib ? null, colors ? null, privatePackages ? {}, ... }:

let
  iso639-lang = pkgs.python3Packages.callPackage ./iso639-lang { };
  bibata-cursors-stylix = pkgs.callPackage ./bibata-cursors-stylix { inherit colors; };
in
{
  inherit iso639-lang bibata-cursors-stylix;
  lyrics = pkgs.callPackage ./lyrics { };
  lazylibrarian = pkgs.callPackage ./lazylibrarian { inherit iso639-lang; };
  jobspy-mcp = pkgs.callPackage ./jobspy-mcp { };
  thunderbird-mcp = pkgs.callPackage ./thunderbird-mcp { };
  codex-acp = pkgs.callPackage ./codex-acp { };
  invidious-companion = pkgs.callPackage ./invidious-companion { };
} // privatePackages
