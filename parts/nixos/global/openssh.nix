{ ... }:
{
  flake.modules.nixos.global-openssh = { outputs, lib, config, ... }:
let
  hosts = lib.filterAttrs (name: _: builtins.pathExists ../../../hosts/${name}/ssh_host_ed25519_key.pub) outputs.nixosConfigurations;
  hostname = config.networking.hostName;
  prefix = "";
  pubKey = host: builtins.toPath (../../../hosts/${host}/ssh_host_ed25519_key.pub);

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXblym20SD75es2z5Qay0mfW+g2zvKPBVMsUFakIyBK diegobarrosaraya@outlook.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpXSRXYbg97jxtfnnitIgNQLvGnLgZBWE9079qD2U4C diego@lazulita"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBM2hEBu4cWTnBMbGdu2bG+sAZu5kBMtc75NFhShmX21"
  ];
in {
  services.openssh = {
    enable = true;

    settings.PasswordAuthentication = false;
    settings.PubkeyAuthentication = true;
    settings.PermitRootLogin = lib.mkForce "prohibit-password";

    extraConfig = ''
      StreamLocalBindUnlink yes
    '';

    settings.GatewayPorts = "clientspecified";

    hostKeys = [{
      path = "${prefix}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  programs.ssh = {

    knownHosts = {};
  };

  security.pam.sshAgentAuth.enable = true;
};
}
