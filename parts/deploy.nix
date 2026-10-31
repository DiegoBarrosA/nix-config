{ config, inputs, ... }:
{
  flake.deploy.nodes.cobalto = {
    hostname = "cobalto";
    fastConnection = false;
    remoteBuild = true;
    magicRollback = false;
    autoRollback = false;
    profiles.system = {
      sshUser = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos config.flake.nixosConfigurations.cobalto;
      user = "root";
    };
  };
}
