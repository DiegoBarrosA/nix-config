{
  config,
  lib,
  pkgs,
  inputs,
  theme ? null,
  ...
}:
let
  schemeType = theme.scheme or "material-darker";
  modeType = theme.mode or "dark";

  stylixBase16 = inputs.stylix.inputs.base16.lib { inherit pkgs lib; };
  tintedSchemes = inputs.stylix.inputs.tinted-schemes;
  isBase = name: builtins.match "base[0-9A-F]{2}" name != null;
  paletteOf = name:
    lib.filterAttrs (k: _: isBase k)
      (stylixBase16.mkSchemeAttrs (tintedSchemes + "/base16/${name}.yaml"));

  nibble = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    a = 10;
    b = 11;
    c = 12;
    d = 13;
    e = 14;
    f = 15;
    A = 10;
    B = 11;
    C = 12;
    D = 13;
    E = 14;
    F = 15;
  };

  channel = hex: i: nibble.${lib.substring i 1 hex};
  toInt = hex: channel hex 0 * 16 + channel hex 1;
  toHex = num:
    let
      hi = builtins.div num 16;
      lo = num - hi * 16;
      digit = d: if d < 10 then toString d else lib.toUpper (lib.toHexString d);
    in
    digit hi + digit lo;

  blend = from: over: t:
    let
      mix = x: y: builtins.floor (x + (y - x) * t + 0.5);
      c = i: toHex (mix (toInt (lib.substring i 2 from)) (toInt (lib.substring i 2 over)));
    in
    "#${c 0}${c 2}${c 4}";
in
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  options.services.cobaltoTheme = {
    scheme = lib.mkOption {
      type = lib.types.str;
      default = schemeType;
    };
    mode = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
      ];
      default = modeType;
    };
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
    };
    base16Scheme = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
    };
    surface = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    services.cobaltoTheme.palette = lib.mkDefault (paletteOf config.services.cobaltoTheme.scheme);
    services.cobaltoTheme.base16Scheme = lib.mkDefault (
      lib.mapAttrs (_: c: "#${c}") config.services.cobaltoTheme.palette
    );
    services.cobaltoTheme.surface = lib.mkDefault (
      blend
        config.services.cobaltoTheme.palette.base00
        config.services.cobaltoTheme.palette.base01
        (1 / 3.0)
    );
    stylix.base16Scheme = config.services.cobaltoTheme.base16Scheme;
  };
}