# Pixel Office for OpenCode — declarative replacement for the upstream
# `opencode-pixel-office install` CLI flow.
#
# Three moving parts:
#   1. opencode-pixel-office package (pixel-office-pkg.nix) — server + built
#      dashboard, exposed as `pixel-office-server`.
#   2. A systemd *user* service that keeps the dashboard server running on :5100.
#   3. The OpenCode plugin (plugin/pixel-office.js) deployed via
#      programs.opencode-config.plugins. The plugin forwards session events to
#      the server; we patch it to also open the dashboard in the default browser
#      ($BROWSER, else xdg-open) once per boot — matching the old plugin's UX.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = 5100;

  app = import ./pixel-office-pkg.nix { inherit pkgs; };

  # Patch the upstream plugin: after it resolves the server endpoint, open the
  # dashboard in the default browser exactly once per boot. The lock file in
  # XDG_RUNTIME_DIR (cleared on reboot) prevents every OpenCode session from
  # spawning its own browser tab. $BROWSER wins over xdg-open so a stale MIME
  # default can never send it to a browser that isn't installed.
  patchedPlugin = pkgs.runCommand "pixel-office-plugin.js" { } ''
    substitute ${app.src}/plugin/pixel-office.js "$out" \
      --replace-fail \
        'const endpoint = resolveEndpoint();' \
        'const endpoint = resolveEndpoint();
  try {
    const cp = await import("node:child_process");
    const lock = (process.env.XDG_RUNTIME_DIR || "/tmp") + "/pixel-office-opened";
    if (!fs.existsSync(lock)) {
      fs.writeFileSync(lock, "1");
      const url = endpoint.replace(/\/events$/, "");
      cp.spawn(process.env.BROWSER || "xdg-open", [url], { stdio: "ignore", detached: true }).unref();
    }
  } catch (e) {}'
  '';
in
{
  # Make `pixel-office-server` available for manual start/stop/debugging.
  home.packages = [ app ];

  # Deploy the event-forwarding plugin into OpenCode's plugin directory.
  programs.opencode-config.plugins."pixel-office.js" = patchedPlugin;

  # Keep the dashboard server running for the user session.
  systemd.user.services.pixel-office = {
    Unit = {
      Description = "Pixel Office dashboard server for OpenCode";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${app}/bin/pixel-office-server";
      Environment = [ "PORT=${toString port}" ];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
