{ pkgs, ... }:
let
  src = pkgs.fetchFromGitHub {
    owner = "Caffa";
    repo = "Session-Character-Visualizer";
    rev = "v1.3.0";
    hash = "sha256-3djkADhWHg8NDiJn0eWw90SpmorNMPdFQpTMwu2vocE=";
  };

  # OpenCode's plugin loader iterates over *every* export of a plugin module
  # and throws "Plugin export is not a function" if any export is not a
  # function. Upstream pixel-office.ts exports the plugin function plus several
  # test-suite helpers, two of which are non-functions (TOOL_STATUS: object,
  # agentFileActivity: Map) -- those make OpenCode reject the entire plugin with
  # error="Plugin export is not a function".
  #
  # The helpers are only consumed by the upstream tests/ suite (which we do not
  # deploy), so we strip the `export` keyword from every top-level declaration
  # except PixelOfficePlugin. The declarations stay in module scope and continue
  # to reference each other, so runtime behaviour is unchanged -- but now the
  # module's sole export is the plugin function itself.
  #
  # Second fix: upstream's "session.status" event handler assumes
  # eventProps.status is a string and calls .toLowerCase() on it. In OpenCode
  # 1.17.7 that field is not always a string, so it throws a TypeError on every
  # status update. We guard the access with a typeof check.
  #
  # Third fix: on Linux the auto-open uses `xdg-open`, which honours the
  # text/html MIME default. We make it prefer an explicit $BROWSER when set, so
  # the viewer always lands in the intended browser even if the MIME default is
  # stale/missing. Falls back to `xdg-open` (the system default) when unset.
  patchedPlugin = pkgs.runCommand "pixel-office-patched.ts" { } ''
    substitute ${src}/pixel-office.ts "$out" \
      --replace-fail 'export function hueFromId('          'function hueFromId(' \
      --replace-fail 'export function folderName('         'function folderName(' \
      --replace-fail 'export const TOOL_STATUS:'           'const TOOL_STATUS:' \
      --replace-fail 'export function toolStatus('         'function toolStatus(' \
      --replace-fail 'export function toolLabel('          'function toolLabel(' \
      --replace-fail 'export const agentFileActivity ='    'const agentFileActivity =' \
      --replace-fail 'export function isIgnored('          'function isIgnored(' \
      --replace-fail 'export function recordFileActivity(' 'function recordFileActivity(' \
      --replace-fail 'export function getActivityScale('   'function getActivityScale(' \
      --replace-fail \
        'const status = (eventProps.status as string).toLowerCase();' \
        'const status = (typeof eventProps.status === "string" ? eventProps.status : "").toLowerCase();' \
      --replace-fail \
        '["xdg-open", viewer]' \
        '[process.env.BROWSER || "xdg-open", viewer]'
  '';
in {
  "pixel-office.ts" = patchedPlugin;
  "pixel-office.html" = "${src}/pixel-office.html";
  "package.json" = "${src}/package.json";
}
