let
  flake = builtins.getFlake "/home/diego/Projects/Personal/nix/nix-config";
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
in {
  topLevel = pkgs ? buildHomeAssistantComponent;
  haPy = pkgs.home-assistant.python.pkgs ? buildHomeAssistantComponent;
  haPyFeedparser = pkgs.home-assistant.python.pkgs ? feedparser;
}
