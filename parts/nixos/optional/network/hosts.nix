{ ... }:
{
  flake.modules.nixos.network-hosts =
{
  config,
  pkgs,
  fetchurl,
  ...
}:

let
  # Pinned to a commit: master moves upstream, which breaks the fixed hash on a clean eval (CI).
  extrahostsfromsteve = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/44175cd295bed844e68c4a057b0a65b418d15ac5/alternates/fakenews-gambling/hosts";
    sha256 = "cuiZmaeeK+ht/g+W5fIu/ER13JNE7e7AaqB7Mf/cBNQ=";
  };
in
{
  networking = {
    extraHosts = "${builtins.readFile extrahostsfromsteve} ";
  };
}
  ;
}
