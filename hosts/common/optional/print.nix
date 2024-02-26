{ pkgs, ... }: {
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };
  services.avahi = {
    enable = true;
    openFirewall = true;
  };
  #services.ipp-usb.enable = true;
  hardware.printers.ensureDefaultPrinter = "main-laser";
}
