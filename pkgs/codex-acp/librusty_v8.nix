{
  lib,
  stdenv,
  fetchurl,
}:

fetchurl {
  name = "librusty_v8-147.4.0";
  url = "https://github.com/denoland/rusty_v8/releases/download/v147.4.0/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
  hash =
    {
      x86_64-linux = "sha256-Cd3vbFEZKv/wVBExoO+cAPgxhdI5HaqxgDgqOr82rJU=";
    }
    .${stdenv.hostPlatform.system}
      or (throw "librusty_v8 147.4.0 hash not recorded for ${stdenv.hostPlatform.system}");
  meta = {
    version = "147.4.0";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
