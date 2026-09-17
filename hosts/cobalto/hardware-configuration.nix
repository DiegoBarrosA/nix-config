{ config, lib, pkgs, modulesPath, inputs, ... }:
let hostname = config.networking.hostName;
in {
  imports = [
    inputs.disko.nixosModules.disko
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "tpm_tis" "tpm_crb" ];

  boot.initrd.kernelModules = [ "r8169" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  disko.devices = {
    disk = {
      cobalto = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WDC_PC_SN520_SDAPNUW-256G-1002_183457800691";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
content = {
                  type = "luks";
                  name = "cobalto-root";
                  passwordFile = "/run/secrets/luks_passphrase";
                  settings = {
                    allowDiscards = true;
                    # Headless unlock order: TPM2 (unattended, PCR 0+7) -> FIDO2
                    # YubiKey fallback -> passphrase slot via initrd SSH (port 2222).
                    # Re-enroll TPM2 after firmware/Secure Boot changes:
                    #   systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 \
                    #     --unlock-key-file=/run/secrets/luks-passphrase <device>
                    # FIDO2 (script: scripts/cobalto-luks-fido2-enroll.sh).
                    # Drop a YubiKey slot when lost:
                    #   cryptsetup luksKillSlot <device> <slot>
                    crypttabExtraOpts = [ "fido2-device=auto" "tpm2-device=auto" ];
                  };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];

                  subvolumes = {

                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    "/persist" = {
                      mountpoint = "/nix/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    "/nix" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/nix";
                    };

                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap = { swapfile.size = "36G"; };
                    };
                  };

                  mountpoint = "/partition-root";

                };
              };
            };
          };
        };
      };
      storage = {
        type = "disk";
        # WD5000LPVX (500G) died and was replaced; this is the ST1000LM024 (931G)
        # that took its bay. Previously held unrelated "onedrive" btrfs data - wiped.
        device = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S31QJ9DH116618";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "luks";
                name = "cobalto-storage";
                passwordFile = "/run/secrets/luks_passphrase";
                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = [ "fido2-device=auto" "tpm2-device=auto" ];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  mountpoint = "/nix/storage";
                  mountOptions = [ "compress=zstd" "nofail" "x-systemd.device-timeout=10" ];
                };
              };
            };
          };
        };
      };
      media = {
        type = "disk";
        # ST3000DM001 (3TB) failed and was replaced with this WD20EARX (1.8T).
        device = "/dev/disk/by-id/ata-WDC_WD20EARX-00PASB0_WD-WCAZAF362077";
        content = {
          type = "gpt";
          partitions = {
            media = {
              size = "100%";
              content = {
                type = "luks";
                name = "cobalto-media";
                passwordFile = "/run/secrets/luks_passphrase";
                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = [ "fido2-device=auto" "tpm2-device=auto" ];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  mountpoint = "/srv/media";
                  mountOptions = [ "compress=zstd" "nofail" "x-systemd.device-timeout=10" ];
                };
              };
            };
          };
        };
      };
  };

  };

  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBM2hEBu4cWTnBMbGdu2bG+sAZu5kBMtc75NFhShmX21"
      ];
    };
  };

  boot.initrd.systemd.network = {
    enable = true;
    networks."10-enp7s0" = {
      matchConfig.Name = "enp7s0";
      networkConfig.DHCP = "no";
      addresses = [
        { Address = "192.168.1.85/24"; }
      ];
      routes = [
        { Gateway = "192.168.1.1"; }
      ];
    };
  };

  # Only root needs to unlock before switch-root. Storage/media are data disks,
  # unlocked in normal (non-initrd) boot via regular crypttab; with "nofail" a
  # missing/dead data disk can no longer block the whole machine from booting
  # (this is what caused the 2026-09-17 outage).
  boot.initrd.luks.devices = {
    "cobalto-root".allowDiscards = true;
  };

  # Legacy path kept during the /mnt/media -> /srv/media migration.
  # Remove once every consumer has been re-pointed.
  fileSystems."/mnt/media" = {
    device = "/srv/media";
    fsType = "none";
    options = [ "bind" ];
  };
}
