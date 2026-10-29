# Group A: layout and docs cleanup

Date: 2026-10-29
Status: draft, waiting for approval

## Intent

The CLAUDE.md audit found five small defects in repo layout and docs. They mislead agents or block their workflow. This spec fixes them in one PR. The change touches no Nix evaluation.

## Goals

1. Agent specs and plans can be committed.
2. No stray files with hardcoded personal paths remain in the repo root.
3. CLAUDE.md describes every top-level directory that exists.
4. No doc points at paths that do not exist.
5. Docs follow the no-dash writing rule.

## Non-goals

- No changes to `parts/`, `flake.nix` or any host config.
- No rewrite of the docs beyond punctuation.
- No fixes for other audit groups.

## Findings and changes

### 1. `.gitignore` blocks agent specs

Line 150 is `docs/superpowers/`. It ignores `docs/superpowers/{specs,plans}/`, which CLAUDE.md and the agent rules tell agents to commit.

Change: remove that line. Nothing else in `.gitignore` changes.

Check: `git check-ignore docs/superpowers/specs/x.md` prints nothing.

### 2. Stray root files

`probe.nix` and `default.nix` are tracked in the repo root. Both call `builtins.getFlake` with a hardcoded `/home/diego/...` path (different paths in each). Nothing in `flake.nix`, `scripts/` or `.github/` references them. `shell.nix` is not in scope and stays.

Change: `git rm probe.nix default.nix`.

Check: `grep -rn 'probe.nix' .` finds nothing outside `.git`. Mentions of `parts/nixos/hosts/<host>/default.nix` in CLAUDE.md are unrelated and stay.

### 3. Top-level `hosts/` is undocumented

CLAUDE.md Layout lists `parts/hosts/` but not the top-level `hosts/` directory. It holds:

- `hosts/cobalto/`: `.sops.yaml`, `secrets.yaml` (sops-encrypted), `secrets.yaml.example`, `deploy_key.pub`.
- `hosts/rubi/`: `.sops.yaml`, `secrets.yaml` (sops-encrypted), `secrets.yaml.template`.
- `hosts/infinix/nix-on-droid.nix`: the nix-on-droid config for infinix.

Change: add one bullet to the Layout section of CLAUDE.md, next to the `parts/hosts/` line, in the style of the neighbouring bullets. Draft:

> `hosts/<host>/`: per-host sops files (`.sops.yaml`, encrypted `secrets.yaml`, examples), `cobalto/deploy_key.pub`, and `infinix/nix-on-droid.nix`. Not a NixOS module tree: NixOS host config lives in `parts/`.

The bullet must not suggest that `hosts/common/` exists (the Conventions section says it does not).

### 4. Stale review prompt

`docs/review-cobalto-impermanence.md` is a review prompt that points at `hosts/cobalto/default.nix`, `hosts/common/optional/system/impermanence.nix` and `hosts/common/global/`. None exist. No file links to it.

Change: `git rm docs/review-cobalto-impermanence.md`. The doc is deleted, not rewritten.

### 5. Dashes in docs

A scan for em dashes (U+2014) and en dashes (U+2013) in `docs/*.md` and `docs/agents/*` finds hits in `docs/media-migration-runbook.md` (lines 8, 67, 125, 148, 230, all `## Phase N — Title` headings), plus the file deleted in item 4. CLAUDE.md has none.

Change: replace each dash in the runbook headings with a colon (`## Phase 0: Pre-flight Checks`). Re-run the scan over all of `docs/`, `CLAUDE.md` and `README*` during the build. For any other hit, pick the comma, colon or parentheses that keeps the sentence correct. Do not use a hyphen as a substitute. Do not touch other text.

Check: `grep -rnP '—|–' docs CLAUDE.md` prints nothing. Fix any Markdown anchors that link to the changed headings (none found so far).

## Constraints

- This spec is committed with `git add -f` because item 1 is not applied yet. Apply item 1 first in the build.
- Conventional commits. One commit per finding is preferred for review.
- Public repo: add no private names or secrets.

## Verification

- `nix flake check --no-build` passes after `git add`.
- The `grep` and `git check-ignore` checks above give the stated results.
- No host build is needed: no file under `parts/` or `flake.nix` changes.

## Open questions

- `shell.nix` looks legitimate (no hardcoded paths seen), so this spec leaves it. Say so if you want it audited too.
- Should `.gitignore` gain a comment explaining why `docs/superpowers/` must stay tracked? Default: no.
