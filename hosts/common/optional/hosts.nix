{ config, pkgs, fetchurl, ... }:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts";
    sha256 = "9sVBMqdmzkfqZ8IjKBSHInhRM1bJ/F8h0tLHmKpizck=";
  };
in {
  networking = { extraHosts = "${builtins.readFile extrahostsfromsteve} "; };
}
