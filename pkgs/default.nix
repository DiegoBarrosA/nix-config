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
  windows-overview = pkgs.callPackage ./windows-overview { };
  spacedrive-v2 = pkgs.callPackage ./spacedrive-v2 { };
  inherit (pkgs.callPackage ./device-mount.nix { }) device-mount device-umount;
} // privatePackages
