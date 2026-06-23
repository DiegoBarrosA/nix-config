{ outputs, lib, config, ... }:
let
  hosts = lib.filterAttrs (name: _: builtins.pathExists ../../${name}/ssh_host_ed25519_key.pub) outputs.nixosConfigurations;
  hostname = config.networking.hostName;
  prefix = "";
  pubKey = host: builtins.toPath (../../${host}/ssh_host_ed25519_key.pub);
  # SSH public keys for authorized access
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXblym20SD75es2z5Qay0mfW+g2zvKPBVMsUFakIyBK diegobarrosaraya@outlook.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpXSRXYbg97jxtfnnitIgNQLvGnLgZBWE9079qD2U4C diego@lazulita"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBM2hEBu4cWTnBMbGdu2bG+sAZu5kBMtc75NFhShmX21"
  ];
in {
  services.openssh = {
    enable = true;
    # Harden
    settings.PasswordAuthentication = false;
    settings.PubkeyAuthentication = true;
    settings.PermitRootLogin = lib.mkForce "prohibit-password";  # Allow key-based access only
    # Automatically remove stale sockets
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
    # Allow forwarding ports to everywhere
    settings.GatewayPorts = "clientspecified";

    hostKeys = [{
      path = "${prefix}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };
  
  # Configure root SSH access
  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  programs.ssh = {
    # Known hosts - disabled to avoid file access errors during first boot
    knownHosts = {};
  };
  # Passwordless sudo when SSH'ing with keys
  security.pam.sshAgentAuth.enable = true;
}
