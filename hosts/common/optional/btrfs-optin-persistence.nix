{ lib, config, pkgs, ... }:
let
  hostname = config.networking.hostName;
  systemdPhase1 = config.boot.initrd.systemd.enable;
  wipeScript = ''
    mkdir -p /btrfs
    mount -o subvol=/ /dev/disk/by-label/${hostname} /btrfs
    if [ -e "/btrfs/root/dontwipe" ]; then
      echo "Not wiping root"
    else
      echo "Cleaning subvolume"
      btrfs subvolume list -o /btrfs/root | cut -f9 -d ' ' |
      while read subvolume; do
        btrfs subvolume delete "/btrfs/$subvolume"
      done && btrfs subvolume delete /btrfs/root
      echo "Restoring blank subvolume"
      btrfs subvolume snapshot /btrfs/root-blank /btrfs/root
    fi
    umount /btrfs
    rm /btrfs
  '';
in {
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  boot.initrd = {
    systemd = lib.mkIf systemdPhase1 {
      emergencyAccess = true;
      initrdBin = with pkgs; [ coreutils btrfs-progs ];
      services.initrd-btrfs-root-wipe = {
        description = "Wipe ephemeral btrfs root";
        script = wipeScript;
        serviceConfig.Type = "oneshot";
        unitConfig.DefaultDependencies = "no";

        # TODO: cycle dependencies are broken
        requires = [ "initrd-root-device.target" ];
        before = [ "sysroot.mount" ];
        wantedBy = [ "initrd-root-fs.target" ];
      };
    };
    # Use postDeviceCommands if on old phase 1
    postDeviceCommands =
      lib.mkBefore (lib.optionalString (!systemdPhase1) wipeScript);
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

    "/nix" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };

    #TODO make function to distingush if the persist is on other disk
    "/persist" = {
      device = "/dev/disk/by-label/${hostname}-persist";
      fsType = "btrfs";
      options = [ "compress=zstd" ];
      neededForBoot = true;
    };

    "/swap" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=swap" "noatime" ];
    };
  };

}
