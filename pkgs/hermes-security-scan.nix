# The security gate as one script: a weak model must not assemble grep pipelines.
# Imported by hermes-agent.nix (PATH of the agent) and parts/checks.nix (the test).
# It lives outside parts/ because import-tree would load every .nix there as a module.
# It never prints a matched term, a pattern or a content line, only FILE:LINE and COMMIT:sha7:field.
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
  # Fixed prefixes: repo diff.* config must not change the filename parsing below.
  gitopts=(-c diff.noprefix=false -c diff.mnemonicPrefix=false -c diff.srcPrefix=a/ -c diff.dstPrefix=b/)
  if [ "$mode" = diff ]; then
    # SHAs, not names: the mirror clone below is scanned by gitleaks, which exits 0 with
    # nothing scanned for a range it cannot resolve.
    basesha=$(git rev-parse --verify --quiet "$base^{commit}") || die "unknown base ref"
    headsha=$(git rev-parse --verify --quiet HEAD) || die "no HEAD"
    git merge-base --is-ancestor "$basesha" "$headsha" || die "base is not an ancestor of HEAD"
    git "''${gitopts[@]}" diff --src-prefix=a/ --dst-prefix=b/ -a -U0 --no-color --no-ext-diff --no-textconv "$basesha..$headsha" > "$tmp/patch"
    lopts=(--log-opts "-m $basesha..$headsha")
  else
    git "''${gitopts[@]}" log --src-prefix=a/ --dst-prefix=b/ -p -m -a -U0 --all --no-color --no-ext-diff --no-textconv --format='commit %H' > "$tmp/patch"
    lopts=(--log-opts "-m --all")
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
  # Terms can also sit in file names and commit metadata. Same terms, same fixed-string
  # case-insensitive match (grep -iF), but print only COMMIT:<sha7>:<field>, never the text.
  # shortcut: one git call per commit, fine for card-sized repos; batch if history scans get slow.
  hasterm() { grep -aqiFf "$tmp/terms" "$tmp/field"; }
  # A git failure must die, not read as "no match".
  chk() { # chk <sha7> <field> <git args...>
    id=$1 field=$2; shift 2
    git "$@" > "$tmp/field" || die "git failed reading commit metadata"
    if hasterm; then echo "COMMIT:$id:$field" >> "$tmp/hits"; fi
  }
  if [ "$mode" = diff ]; then revs=("$basesha..$headsha"); else revs=(--all); fi
  git rev-list "''${revs[@]}" > "$tmp/shas" || die "cannot list commits"
  while read -r sha; do
    id=''${sha:0:7}
    chk "$id" message log -1 --format=%B "$sha"
    chk "$id" author log -1 --format='%an%n%ae' "$sha"
    chk "$id" committer log -1 --format='%cn%n%ce' "$sha"
    # -z so odd names are not quoted into escapes; -m so merges list their files too.
    chk "$id" path diff-tree -r -m --root --no-commit-id --name-only -z "$sha"
  done < "$tmp/shas"
  matches=$(wc -l < "$tmp/hits")
  cat "$tmp/hits"

  # Exit 2 means leaks, so gitleaks's own fatal exit 1 cannot pass as findings.
  # gitleaks honours a .gitleaksignore found in the worktree or committed in the repo, even with
  # --gitleaks-ignore-path, so scan a bare clone: it has no worktree, and the clone is by object
  # content (--mirror keeps refs/remotes too). The empty ignore dir and --ignore-gitleaks-allow cover the rest.
  git clone -q --mirror --no-local . "$tmp/bare" >/dev/null 2>&1 || die "bare clone failed"
  mkdir "$tmp/noignore"
  # An unscannable range makes gitleaks exit 0 with nothing scanned. An empty range is fine.
  if [ "$mode" = diff ]; then
    git -C "$tmp/bare" rev-list "$basesha..$headsha" >/dev/null || die "range is not scannable"
  fi
  rc=0
  gitleaks detect --no-banner --redact --exit-code 2 --config ${config} \
    --gitleaks-ignore-path "$tmp/noignore" --ignore-gitleaks-allow -s "$tmp/bare" \
    "''${lopts[@]}" --report-format json --report-path "$tmp/leaks.json" >"$tmp/gitleaks.log" 2>&1 || rc=$?
  case "$rc" in 0|2) ;; *) die "gitleaks failed with exit $rc" ;; esac
  [ -f "$tmp/leaks.json" ] || die "gitleaks wrote no report"
  # A range with commits must show as scanned: gitleaks exits 0 having scanned nothing for a range it misreads.
  if [ "$mode" = diff ] && [ "$(git -C "$tmp/bare" rev-list --count "$basesha..$headsha")" -gt 0 ]; then
    scanned=$(grep -Eo "[0-9]+ commits scanned" "$tmp/gitleaks.log" | head -1 | cut -d" " -f1)
    [ "''${scanned:-0}" -gt 0 ] || die "gitleaks scanned no commits"
  fi
  jq -e 'type == "array"' "$tmp/leaks.json" >/dev/null || die "gitleaks report is not valid JSON"
  # -m reports a merge commit once per parent: count each fingerprint once.
  secrets=$(jq "[.[].Fingerprint] | unique | length" "$tmp/leaks.json")

  echo "terms=$n matches=$matches secrets=$secrets"
  if [ "$matches" -eq 0 ] && [ "$secrets" -eq 0 ]; then final=0; else final=1; fi
  exit $final
''
