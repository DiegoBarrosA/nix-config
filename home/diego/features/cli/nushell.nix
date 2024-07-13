{
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "hx";
      top = "btm";
    };
    # extraConfig = "";
  };
  home.shellAliases = { moe = "iina https://listen.moe/stream"; };
}
