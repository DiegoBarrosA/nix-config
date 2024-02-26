{ config, pkgs, fetchurl, ... }:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts";
    sha256 = "P+z29TMZSzavzskxnHkoM7qFq4AdiHfk8zkzdXnfIes=";
  };
in {
  networking = { extraHosts = "${builtins.readFile extrahostsfromsteve} "; };
}
