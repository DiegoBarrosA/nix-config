{
  config,
  pkgs,
  fetchurl,
  ...
}:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
    sha256 = "wBdsdgdZ8YnxFzcR1SEoZ7tmolD73qLNdhcqy8aZxXg=";

  };
in
{
  networking = {
    extraHosts = "${builtins.readFile extrahostsfromsteve} ";
  };
}
