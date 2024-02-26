{ config, ... }: {
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.64.141.72/32" "fc00:bbbb:bbbb:bb01::1:8d47/128" ];
      dns = [ "100.64.0.31" ];
      privateKeyFile = config.sops.secrets.wg-privateKey.path;
      peers = [{
        publicKey = "Qn1QaXYTJJSmJSMw18CGdnFiVM0/Gj/15OdkxbXCSG0=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "193.138.218.220:51820";
        persistentKeepalive = 25;
      }];
    };
  };
  sops.secrets = { wg-privateKey = { sopsFile = ../secrets.yaml; }; };

}
