# Steam gaming module — tuned for fast play on rubi's hardware.
#
# Hardware target (rubi):
#   - AMD Ryzen APU with integrated Radeon 680M (RDNA2, gfx1035)
#   - Mesa RADV is the default Vulkan driver — no ICD override needed
#   - System default cpuFreqGovernor is "powersave"; GameMode flips it to
#     "performance" only while a game runs, then restores it.
#
# Notes:
#   - Steam needs 32-bit graphics libraries. We enable hardware.graphics.
#     enable32Bit here (verified to build on current nixpkgs — the stale
#     "i686 broken" comment in hardware-configuration.nix no longer applies).
#   - rubi persists /home/diego entirely (see impermanence.nix), so
#     ~/.steam and ~/.local/share/Steam game libraries survive reboots with
#     no extra persistence wiring.
{
  lib,
  pkgs,
  ...
}:
{
  # 32-bit graphics libraries — REQUIRED for Steam and most games/Proton.
  hardware.graphics.enable32Bit = true;

  programs.steam = {
    enable = true;

    # Steam Input on Wayland needs extest to translate X11 input events to
    # uinput (controllers, Steam Controller, etc.).
    extest.enable = true;

    # protontricks for per-game Winetricks tweaks.
    protontricks.enable = true;

    # Open firewall for Remote Play and local-network game transfers.
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = false;

    # GE-Proton: community Proton build with extra game fixes/patches.
    # Selectable per-game in Steam: Properties → Compatibility → GE-Proton.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # GameMode: the main "play fast" lever. On launch it switches the CPU
  # governor to performance, applies I/O priority, and renices the game
  # process; on exit it restores prior settings. Launch games with
  # `gamemoderun %command%` in Steam, or globally via the steam launch option.
  programs.gamemode = {
    enable = true;
    enableRenice = true; # allow lowering game process niceness (needs CAP_SYS_NICE)
    settings = {
      general = {
        renice = 10;
        # AMD APU: bias toward performance while gaming.
        desiredgov = "performance";
        igpu_desiredgov = "performance";
      };
    };
  };

  # gamescope: micro-compositor for clean fullscreen/upscaling on Wayland;
  # eliminates compositor stutter and supports FSR. Run a game inside it with
  # `gamescope -W <w> -H <h> -f -- %command%`.
  programs.gamescope = {
    enable = true;
    capSysNice = true; # let gamescope renice itself for lower latency
  };

  # Handy gaming tools available system-wide.
  environment.systemPackages = with pkgs; [
    mangohud # FPS / frametime / temps overlay (mangohud %command%)
    protonup-qt # GUI to manage Proton-GE versions
  ];
}
