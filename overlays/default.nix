# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # NixGL overlay for graphics support on non-NixOS systems
  nixgl = inputs.nixgl.overlay;

  # Python 3.14 metadata compatibility shim.
  # All python-tree-sitter-* language packages (graphify deps) fail
  # pythonMetadataCheckPhase under Python 3.14 — importlib.metadata cannot
  # locate their dist-info. Disable doInstallCheck for all of them at once
  # so graphify and any other dependents still build.
  pythonFixes = _final: prev: {
    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (_self: super:
        let
          tsLangs = [
            "python-tree-sitter-c"
            "python-tree-sitter-c-sharp"
            "python-tree-sitter-cpp"
            "python-tree-sitter-elixir"
            "python-tree-sitter-go"
            "python-tree-sitter-java"
            "python-tree-sitter-javascript"
            "python-tree-sitter-julia"
            "python-tree-sitter-kotlin"
            "python-tree-sitter-lua"
            "python-tree-sitter-objc"
            "python-tree-sitter-php"
            "python-tree-sitter-powershell"
            "python-tree-sitter-python"
            "python-tree-sitter-ruby"
            "python-tree-sitter-rust"
            "python-tree-sitter-scala"
            "python-tree-sitter-swift"
            "python-tree-sitter-typescript"
            "python-tree-sitter-verilog"
            "python-tree-sitter-zig"
          ];
          skipMeta = name:
            if super ? ${name}
            then { ${name} = super.${name}.overridePythonAttrs (_old: { dontCheckPythonMetadata = true; }); }
            else { };
        in
        builtins.foldl' (acc: name: acc // skipMeta name) { } tsLangs
      )
    ];
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    dummy = prev.hello;

    # xdg-desktop-portal-wlr 0.8.3 deadlocks screencasts after the first frame.
    # The ext_image_copy_capture_v1 path negotiates a 2-buffer pool, the consumer
    # holds both, pw_stream_dequeue_buffer() returns NULL and nothing re-arms the
    # capture loop ("out of buffers" / "unable to export buffer"). Hits every
    # browser because it sits below them, in the portal. Upstream issue #395,
    # fixed by PR #397 and released in 0.8.4.
    # Remove once nixos-unstable ships >= 0.8.4 (nixpkgs PR #546818, on master
    # since 2026-07-30 but not yet through Hydra).
    xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (_oldAttrs: {
      version = "0.8.4";
      src = final.fetchFromGitHub {
        owner = "emersion";
        repo = "xdg-desktop-portal-wlr";
        rev = "v0.8.4";
        sha256 = "sha256-8Ohgkz13FcG8ddjjgreXkvFD2Q+zUDZnAM4Oh+C9P/s=";
      };
    });

    ncmpcpp = prev.ncmpcpp.overrideAttrs (oldAttrs: rec {
      visualizerSupport = true;
      clockSupport = true;
    });

    # homepage-dashboard: build from dev branch for syncthing widget (PR #6865, merged 2026-07-13)
    # Remove once nixpkgs ships a version ≥ 1.14.0
    homepage-dashboard = prev.homepage-dashboard.overrideAttrs (oldAttrs: {
      version = "1.13.2-dev-unstable";
      src = final.fetchFromGitHub {
        owner = "gethomepage";
        repo = "homepage";
        rev = "84c7e5126977ca2f58ccf3caa46c88eaf670c5dd";
        hash = "sha256-qR81EMAJL2tL9BshzQuEOV9fFCHidXRHJM4gPFGy2Vo=";
      };
      pnpmDeps = final.fetchPnpmDeps {
        pname = "homepage-dashboard";
        version = "1.13.2-dev-unstable";
        src = final.fetchFromGitHub {
          owner = "gethomepage";
          repo = "homepage";
          rev = "84c7e5126977ca2f58ccf3caa46c88eaf670c5dd";
          hash = "sha256-qR81EMAJL2tL9BshzQuEOV9fFCHidXRHJM4gPFGy2Vo=";
        };
        pnpm = final.pnpm_10;
        fetcherVersion = 3;
        hash = "sha256-zWvSivqwAMO6EFhYgXUyxJQsJTwvhmExu6t+EIwCFqs=";
      };
    });


    # xdg-utils-spawn-terminal = prev.xdg-utils.overrideAttrs (oldAttrs: {
    #   patches = (oldAttrs.patches or [ ]) ++ [ ./xdg-open-spawn-terminal.diff ];
    # });

    # pfetch = prev.pfetch.overrideAttrs (oldAttrs: {
    #   version = "unstable-2021-12-10";
    #   src = final.fetchFromGitHub {
    #     owner = "dylanaraps";
    #     repo = "pfetch";
    #     rev = "a906ff89680c78cec9785f3ff49ca8b272a0f96b";
    #     sha256 = "sha256-9n5w93PnSxF53V12iRqLyj0hCrJ3jRibkw8VK3tFDvo=";
    #   };
    #   # Add term option, rename de to desktop, add scheme option
    #   patches = (oldAttrs.patches or [ ]) ++ [ ./pfetch.patch ];
    # });

    # Sane default values and crash avoidance (https://github.com/k-vernooy/trekscii/pull/1)

    # python-miio: Fix click 8 compatibility (Group.__init__ has a `commands` param
    # that causes `TypeError: argument of type 'bool' is not iterable` when
    # positional args are used)
    # NOTE: Only apply on x86_64-linux to avoid i686-linux pypy eval failure
    python3Packages = if final.stdenv.hostPlatform.system != "i686-linux" then
      prev.python3Packages.override {
        overrides = self: super: {
          python-miio = super.python-miio.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./python-miio-click-8-compat.patch ];
          });

          pymp4 = self.callPackage ../pkgs/pymp4 { };

          pywidevine = self.callPackage ../pkgs/pywidevine {
            inherit (final) shaka-packager;
          };

          construct = self.callPackage ../pkgs/construct { };
        };
      }
    else
      prev.python3Packages;

  };
}
