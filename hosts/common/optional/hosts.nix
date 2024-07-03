{ config, pkgs, fetchurl, ... }:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
    sha256 = "weNWLuIqyvQdYb1Y/pCB7DBjcoT42MvxnKy45NPupZo=";
  };
in {
  networking = { extraHosts = "${builtins.readFile extrahostsfromsteve} "; };
}
