{ config, inputs, pkgs, ... }:
{
  imports = [
../common/darwin

  ];
users.users.diego = {
  name = "diego";
  #home = "/Users/diego";
};
  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";
  # Auto upgrade nix package and the daemon service.

  # Create /etc/zshrc that loads the nix-darwin environment.
 programs.zsh.enable = true;  # default shell on catalina
 services.emacs.enable = true;
homebrew.enable = true;
homebrew.casks = [
{ name = "firefox"; }
{ name = "keepassxc"; }
{ name = "syncthing"; }
];
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
