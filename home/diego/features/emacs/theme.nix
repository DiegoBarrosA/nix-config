{ emacsPackagesFor, writeText, config, ... }:
let
  emacsPackages = emacsPackagesFor config.programs.emacs.package;
  scheme = config.colorScheme;
in emacsPackages.trivialBuild {
  pname = "theme";
  version = "1";
  src = writeText "nix-${scheme.slug}.el" # commonlisp
    ''
      (require 'base16-theme)

      (defvar base16-${scheme.slug}-theme-palette
        '(:base00 "#${scheme.palette.base00}"
          :base01 "#${scheme.palette.base01}"
          :base02 "#${scheme.palette.base02}"
          :base03 "#${scheme.palette.base03}"
          :base04 "#${scheme.palette.base04}"
          :base05 "#${scheme.palette.base05}"
          :base06 "#${scheme.palette.base06}"
          :base07 "#${scheme.palette.base07}"
          :base08 "#${scheme.palette.base08}"
          :base09 "#${scheme.palette.base09}"
          :base0A "#${scheme.palette.base0A}"
          :base0B "#${scheme.palette.base0B}"
          :base0C "#${scheme.palette.base0C}"
          :base0D "#${scheme.palette.base0D}"
          :base0E "#${scheme.palette.base0E}"
          :base0F "#${scheme.palette.base0F}")
        "All palette for Base16 ${scheme.name} are defined here.")

      ;; Define the theme
      (deftheme base16-${scheme.slug})

      ;; Add all the faces to the theme
      (base16-theme-define 'base16-${scheme.slug} base16-${scheme.slug}-theme-palette)

      ;; Mark the theme as provided
      (provide-theme 'base16-${scheme.slug})

      (provide 'base16-${scheme.slug}-theme)
    '';
  packageRequires = [ emacsPackages.base16-theme ];
}
