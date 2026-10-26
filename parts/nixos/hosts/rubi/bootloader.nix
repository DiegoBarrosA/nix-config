{ ... }:
{
  flake.modules.nixos.rubi-bootloader = { pkgs, ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      editor = false;
      graceful = true;

      configurationLimit = 10;

      extraInstallCommands = ''
        ${pkgs.sbctl}/bin/sbctl sign /boot/EFI/systemd/systemd-bootx64.efi --save || true
        for kernel in /boot/EFI/nixos/*bzImage.efi; do
          [ -e "$kernel" ] || continue
          ${pkgs.sbctl}/bin/sbctl sign "$kernel" --save || true
        done
      '';
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    timeout = 0;
  };
};
}
