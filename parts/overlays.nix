{ inputs, ... }:
{
  flake.overlays = import ./_overlays { inherit inputs; };
}
