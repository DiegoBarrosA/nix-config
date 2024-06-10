let
  wallpaper = builtins.fetchurl {
    url =
      "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-nineish.src.svg";
    sha256 = "059hjcnpy7jj8bijs2xbjmwfc41dxy4pl801nkhblrdxiny21s0h";
  };
in {

  programs.wpaperd = {
    enable = true;
    settings = { any = { path = "${wallpaper}"; }; };
  };
}
