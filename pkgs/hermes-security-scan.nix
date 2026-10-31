# The security gate as one script: a weak model must not assemble grep pipelines.
# Imported by hermes-agent.nix (PATH of the agent) and parts/checks.nix (the test).
# It lives outside parts/ because import-tree would load every .nix there as a module.
# It never prints a matched term, a pattern or a content line, only FILE:LINE.
pkgs:
pkgs.writeShellScriptBin "hermes-security-scan" ''
  set -euo pipefail
  export PATH=${pkgs.lib.makeBinPath [ pkgs.git pkgs.gitleaks pkgs.gawk pkgs.coreutils ]}:$PATH
  die() { echo "hermes-security-scan: $1" >&2; exit 3; }

  mode=''${1:-}
  case "$mode" in
    diff) base=''${2:-}; [ -n "$base" ] || die "usage: hermes-security-scan diff <base-ref>" ;;
    history) base= ;;
    *) die "usage: hermes-security-scan diff <base-ref> | history" ;;
  esac
  command -v git >/dev/null || die "git is missing"
  command -v gitleaks >/dev/null || die "gitleaks is missing"

  # Env override exists only for the flake check.
  terms=''${HERMES_SECURITY_TERMS:-/run/secrets/hermes-security-terms}
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  [ -r "$terms" ] || die "term list is not configured (missing or unreadable)"
  awk '{ gsub(/\r/, "") } NF' "$terms" > "$tmp/terms" || die "cannot read the term list"
  n=$(wc -l < "$tmp/terms")
  [ "$n" -ge 1 ] || die "term list is not configured (no patterns)"

  if [ "$mode" = diff ]; then
    git rev-parse --verify --quiet "$base^{commit}" >/dev/null || die "unknown base ref"
    git diff -U0 --no-color --no-ext-diff "$base..HEAD" > "$tmp/patch" || die "git diff failed"
    lopts=(--log-opts "$base..HEAD")
  else
    git log -p -U0 --all --no-color --no-ext-diff --format='commit %H' > "$tmp/patch" || die "git log failed"
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

  rc=0
  gitleaks detect --no-banner --redact "''${lopts[@]}" --report-format json --report-path "$tmp/leaks.json" || rc=$?
  case "$rc" in 0|1) ;; *) die "gitleaks failed with exit $rc" ;; esac
  secrets=$(grep -o '"RuleID"' "$tmp/leaks.json" | wc -l || true)

  echo "terms=$n matches=$matches secrets=$secrets"
  [ "$matches" -eq 0 ] && [ "$secrets" -eq 0 ] || exit 1
''
