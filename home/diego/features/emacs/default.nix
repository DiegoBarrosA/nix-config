{ lib, inputs, pkgs, config, ... }:
let
  emacs-overlay = inputs.emacs-overlay.packages.${pkgs.system};
  inherit (pkgs) stdenv;
  inherit (lib) mkIf;
in {
  programs.emacs = {
    enable = true;
    overrides = final: _prev: {
      nix-theme = final.callPackage ./theme.nix { inherit config; };
      buildInputs = final.buildInputs ++ [ final.jansson final.harfbuzz ];
    };
    extraPackages = epkgs:
      with epkgs; [
        org-modern
        company
        projectile
        lsp-mode
        doom-modeline
        js2-mode
        cask
        nix-theme
        treemacs
        treemacs-magit
        treemacs-tab-bar
        nix-mode
        treemacs-evil
        magit
        lsp-mode
        which-key
        mmm-mode
        rust-mode
        typescript-mode
        evil
        evil-org
        evil-collection
        evil-surround
        format-all
        vterm
        evil-collection
        undo-tree
        zen-mode
        org-roam
        org-roam-ui
        org-roam-timestamps
        org-roam-bibtex
        sqlite3
        groovy-mode
        general
        nerd-icons
        python-mode
        python
      ];
    package = if pkgs.stdenv.isDarwin then
      emacs-overlay.emacs-pgtk.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # Fix OS window role (needed for window managers like yabai)
          (pkgs.fetchpatch {
            url =
              "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
            sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
          })
          # Use poll instead of select to get file descriptors
          (pkgs.fetchpatch {
            url =
              "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-29/poll.patch";
            sha256 = "sha256-jN9MlD8/ZrnLuP2/HUXXEVVd6A+aRZNYFdZF8ReJGfY=";
          })
          # Enable rounded window with no decoration
          (pkgs.fetchpatch {
            url =
              "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/round-undecorated-frame.patch";
            sha256 = "sha256-uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
          })
          # Make Emacs aware of OS-level light/dark moe
          (pkgs.fetchpatch {
            url =
              "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/system-appearance.patch";
            sha256 = "sha256-oM6fXdXCWVcBnNrzXmF0ZMdp8j0pzkLE66WteeCutv8=";
          })
        ];
      })
    else
      emacs-overlay.emacs-ptgk;
    extraConfig = builtins.readFile ./init.el;
  };
  services.emacs = mkIf stdenv.isLinux {
    client.enable = true;
    enable = true;
    defaultEditor = true;
    socketActivation.enable = true;
  };
}
