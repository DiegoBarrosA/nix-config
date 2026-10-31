{ ... }:
{
  flake.modules.homeManager.bar =
{ lib, ... }:
{
  options.bar.height = lib.mkOption {
    type = lib.types.int;
    default = 36;
    description = "Height in px of the status bar (i3status-rs), shared with UI that should align to it.";
  };
};
}
