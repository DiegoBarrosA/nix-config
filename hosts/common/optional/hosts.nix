{
  config,
  pkgs,
  fetchurl,
  ...
}:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
    sha256 = "CSjWrKuSLq8eh2hOthL8Ydz0xNbzOS3ouRphKWDpDLc=";

  };
in
{
  networking = {
    extraHosts = "${builtins.readFile extrahostsfromsteve} ";
  };
}
