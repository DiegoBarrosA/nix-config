# This file defines overlays
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

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

  };
}
