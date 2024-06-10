{ config, pkgs, fetchurl, ... }:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts";
    sha256 = "ue9Q78OEPpkAdwdy+yvzYz9J3Zz0c4eJPwCOB3J8h38=";
  };
in {
  networking = { extraHosts = "${builtins.readFile extrahostsfromsteve} "; };
}
