# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # NixGL overlay for graphics support on non-NixOS systems
  nixgl = inputs.nixgl.overlay;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    dummy = prev.hello;
    
    
    ncmpcpp = prev.ncmpcpp.overrideAttrs (oldAttrs: rec {
      visualizerSupport = true;
      clockSupport = true;
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
