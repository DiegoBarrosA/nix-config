{ config, pkgs, fetchurl, ... }:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
    sha256 = "3rzdFSFUTMbwmKmrT4Q0nok/7TvC8HX7IiI1lFGjmLM=";
  };
in {
  networking = { extraHosts = "${builtins.readFile extrahostsfromsteve} "; };
}
