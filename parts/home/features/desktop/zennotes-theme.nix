{ ... }:
{
  flake.modules.homeManager.desktop-zennotes-theme =
{ config, lib, ... }:
let
  inherit (config.colorscheme) colors;

  hexToRgb =
    hex:
    let
      n = lib.trivial.fromHexString hex;
      r = n / 65536;
      g = (n / 256) - (r * 256);
      b = n - (r * 65536) - (g * 256);
    in
    "${toString r} ${toString g} ${toString b}";

  c = builtins.mapAttrs (_: hexToRgb) colors;

  themeCss = ''
    :root {
      color-scheme: dark;

      --z-bg: ${c.base00};
      --z-bg-softer: ${c.base00};
      --z-bg-1: ${c.base01};
      --z-bg-2: ${c.base02};
      --z-bg-3: ${c.base03};
      --z-bg-4: ${c.base04};

      --z-fg: ${c.base05};
      --z-fg-1: ${c.base06};
      --z-fg-2: ${c.base04};
      --z-grey-2: ${c.base04};
      --z-grey-1: ${c.base03};
      --z-grey-0: ${c.base02};
      --z-grey-dim: ${c.base01};

      --z-accent: ${c.base0D};
      --z-accent-soft: ${c.base09};
      --z-accent-muted: ${c.base0B};

      --z-red: ${c.base08};
      --z-green: ${c.base0B};
      --z-yellow: ${c.base0A};
      --z-blue: ${c.base0D};
      --z-purple: ${c.base0E};
      --z-aqua: ${c.base0C};

      --z-shadow: ${c.base00};
    }
  '';

  manifest = builtins.toJSON {
    name = "Base16 (active)";
    author = "generated from colorscheme.colors";
    version = "1.0.0";
    description = "Mirrors this host's active base16 colorscheme.";
    modes = "dark";
  };
in
{
  xdg.configFile."zennotes/themes/base16-active/manifest.json".text = manifest;
  xdg.configFile."zennotes/themes/base16-active/theme.css".text = themeCss;
};
}
