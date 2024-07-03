# iso.nix
{ pkgs, ... }: {
  imports = [
    # installation-cd-graphical-plasma5-new-kernel.nix uses pkgs.linuxPackages_latest
    # instead of the default kernel.
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    wget
    vim
    git
    tmux
    gparted
    nix-prefetch-scripts
  ];
}
