{
  config,
  pkgs,
  fetchurl,
  ...
}:

let
  extrahostsfromsteve = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
    sha256 = "RFczQUpf62uMfa+QunqlwQKL7CA4AHaOmRDz4FmjKDo=";

  };
in
{
  networking = {
    extraHosts = "${builtins.readFile extrahostsfromsteve} ";
  };
}
