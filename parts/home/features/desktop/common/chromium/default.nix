{ ... }:
{
  flake.modules.homeManager.desktop-common-chromium =
{
  pkgs,
  ...
}:
{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    extensions = [
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; } # Claude in Chrome
    ];
  };
};
}
