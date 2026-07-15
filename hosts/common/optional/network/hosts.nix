{
  config,
  pkgs,
  fetchurl,
  ...
}:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
    sha256 = "U/afX0X36G+QTVEpwertzV65v/NmT0drkaR4PmUFuZY=";

  };
in
{
  networking = {
    extraHosts = "${builtins.readFile extrahostsfromsteve} ";
  };
}
