# The security gate as one script: a weak model must not assemble grep pipelines.
# Imported by hermes-agent.nix (PATH of the agent) and parts/checks.nix (the test).
# It lives outside parts/ because import-tree would load every .nix there as a module.
# It never prints a matched term, a pattern or a content line, only FILE:LINE.
# The term path is a Nix argument, not an env var: an env override would let the
# agent point the scan at its own one-term file and pass.
{
  pkgs,
  terms ? "/run/secrets/hermes-security-terms",
  gitleaks ? pkgs.gitleaks,
}:
let
  # The repo's own .gitleaks.toml would let a card allowlist its secrets, so pin a config.
  config = pkgs.writeText "gitleaks.toml" ''
    [extend]
    useDefault = true
  '';
in
pkgs.writeShellScriptBin "hermes-security-scan" ''
  set -euo pipefail
  export PATH=${pkgs.lib.makeBinPath [ pkgs.git gitleaks pkgs.gawk pkgs.coreutils pkgs.jq ]}:$PATH
  # Env that gitleaks reads would weaken the scan.
  unset GITLEAKS_CONFIG GITLEAKS_CONFIG_TOML

  # Every death exits 3. Only the two explicit statuses below may be 0 or 1.
  final=3
  tmp=
  trap 'rm -rf "$tmp"; exit $final' EXIT
  die() { echo "hermes-security-scan: $1" >&2; exit 3; }

  mode=''${1:-}
  case "$mode" in
    diff) base=''${2:-}; [ -n "$base" ] || die "usage: hermes-security-scan diff <base-ref>" ;;
    history) base= ;;
    *) die "usage: hermes-security-scan diff <base-ref> | history" ;;
  esac

  tmp=$(mktemp -d)
  [ -r ${terms} ] || die "term list is not configured (missing or unreadable)"
  # Strip CR, trim each term, drop blank lines.
  awk '{ gsub(/\r/, ""); gsub(/^[ \t]+|[ \t]+$/, "") } NF' ${terms} > "$tmp/terms"
  n=$(wc -l < "$tmp/terms")
  [ "$n" -ge 1 ] || die "term list is not configured (no patterns)"

  # -a and --no-textconv: a -diff attribute or textconv driver in the scanned repo must not hide content.
  if [ "$mode" = diff ]; then
    git rev-parse --verify --quiet "$base^{commit}" >/dev/null || die "unknown base ref"
    git -c diff.noprefix=false -c diff.mnemonicPrefix=false diff -a -U0 --no-color --no-ext-diff --no-textconv "$base..HEAD" > "$tmp/patch"
    lopts=(--log-opts "$base..HEAD")
  else
    git -c diff.noprefix=false -c diff.mnemonicPrefix=false log -p -m -a -U0 --all --no-color --no-ext-diff --no-textconv --format='commit %H' > "$tmp/patch"
    lopts=()
  fi

  # Only added lines are matched. Hunk headers give the new line number.
  awk -v mode="$mode" '
    NR == FNR { p[++np] = tolower($0); next }
    /^commit / && mode == "history" { c = substr($0, 8); next }
    /^diff --git/ { hdr = 1; next }
    hdr && /^\+\+\+ / { f = substr($0, 5); sub(/^b\//, "", f); if (f == "/dev/null") f = ""; next }
    /^@@/ { hdr = 0; s = $0; sub(/^@@ -[0-9,]+ \+/, "", s); sub(/[ ,].*/, "", s); ln = s + 0; next }
    /^\+/ {
      l = tolower(substr($0, 2))
      for (i = 1; i <= np; i++) if (index(l, p[i])) {
        k = (mode == "history") ? c ":" f : f ":" ln
        if (!(k in seen)) { seen[k] = 1; print k }
        break
      }
      ln++
    }' "$tmp/terms" "$tmp/patch" > "$tmp/hits"
  matches=$(wc -l < "$tmp/hits")
  cat "$tmp/hits"

  # Exit 2 means leaks, so gitleaks's own fatal exit 1 cannot pass as findings.
  # gitleaks honours a .gitleaksignore found in the worktree or committed in the repo, even with
  # --gitleaks-ignore-path, so scan a bare clone: it has no worktree, and the clone is by object
  # content. The empty ignore dir and --ignore-gitleaks-allow cover the rest.
  git clone -q --bare --no-local . "$tmp/bare" >/dev/null 2>&1 || die "bare clone failed"
  mkdir "$tmp/noignore"
  rc=0
  gitleaks detect --no-banner --redact --exit-code 2 --config ${config} \
    --gitleaks-ignore-path "$tmp/noignore" --ignore-gitleaks-allow -s "$tmp/bare" \
    "''${lopts[@]}" --report-format json --report-path "$tmp/leaks.json" >/dev/null 2>&1 || rc=$?
  case "$rc" in 0|2) ;; *) die "gitleaks failed with exit $rc" ;; esac
  [ -f "$tmp/leaks.json" ] || die "gitleaks wrote no report"
  jq -e 'type == "array"' "$tmp/leaks.json" >/dev/null || die "gitleaks report is not valid JSON"
  secrets=$(jq length "$tmp/leaks.json")

  echo "terms=$n matches=$matches secrets=$secrets"
  if [ "$matches" -eq 0 ] && [ "$secrets" -eq 0 ]; then final=0; else final=1; fi
  exit $final
''
