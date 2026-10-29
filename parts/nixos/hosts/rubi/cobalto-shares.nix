{ ... }:
{
  # Cobalto's Samba shares, mounted on first access and unmounted when idle.
  flake.modules.nixos.rubi-cobalto-shares =
    { config, lib, ... }:
    let
      shares = [
        "media"
        "storage"
      ];
    in
    {
      # The sops secret holds only the Samba password. mount.cifs needs a
      # username= line too, so render a credentials file from it.
      sops.secrets."cobalto-smb-credentials" = { };
      sops.templates."cobalto-smb.cred" = {
        owner = "root";
        group = "root";
        mode = "0400";
        content = "username=diego\npassword=${config.sops.placeholder."cobalto-smb-credentials"}\n";
      };

      fileSystems = lib.listToAttrs (
        map (
          share:
          lib.nameValuePair "/mnt/cobalto/${share}" {
            device = "//cobalto/${share}";
            fsType = "cifs";
            options = [
              "credentials=${config.sops.templates."cobalto-smb.cred".path}"
              "uid=diego"
              "gid=users"
              "file_mode=0664"
              "dir_mode=0775"
              # Mount on first access, so a missing network never delays boot.
              "noauto"
              "nofail"
              "_netdev"
              "x-systemd.automount"
              "x-systemd.idle-timeout=120"
              "x-systemd.mount-timeout=10s"
            ];
          }
        ) shares
      );
    };
}
