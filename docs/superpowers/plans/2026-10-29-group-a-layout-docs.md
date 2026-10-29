# Group A: layout and docs cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the five Group A audit findings (gitignore, stray files, hosts/ docs, stale review doc, dashes) in one PR.

**Architecture:** Five independent file-level edits, one commit each. No Nix evaluation changes.

**Tech Stack:** git, grep, `nix flake check --no-build`.

**Spec:** `docs/superpowers/specs/2026-10-29-group-a-layout-docs.md`

## Global Constraints

- Do not change `parts/`, `flake.nix` or any host config.
- Use no em dashes or en dashes in anything you write. Do not substitute a hyphen.
- Conventional commits, one per task, each ending with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- The repo is public: add no private names or secrets.

## Review Focus

- A dash replacement that breaks a Markdown anchor link: grep for `#phase` links to the runbook headings.
- A `.gitignore` edit that removes more than the one line: check the diff shows one deletion.
- A CLAUDE.md bullet that contradicts "Do not add `hosts/common/`": read the final Layout section.

---

### Task 1: Stop ignoring agent specs

**Files:**
- Modify: `.gitignore` (delete the line `docs/superpowers/`)

- [ ] **Step 1: Delete the `docs/superpowers/` line from `.gitignore`.**
- [ ] **Step 2: Verify.** Run `git check-ignore docs/superpowers/specs/x.md; echo $?`. Expected: no path printed, exit code 1. Run `git diff --stat .gitignore`. Expected: 1 deletion.
- [ ] **Step 3: Commit** `fix(gitignore): track docs/superpowers specs and plans`.

### Task 2: Remove stray root files

**Files:**
- Delete: `probe.nix`, `default.nix`

- [ ] **Step 1: Run `git rm probe.nix default.nix`.**
- [ ] **Step 2: Verify.** Run `grep -rn 'probe.nix' . --exclude-dir=.git`. Expected: no output except this plan and the spec.
- [ ] **Step 3: Commit** `chore: remove stray root nix files with hardcoded paths`.

### Task 3: Document top-level `hosts/`

**Files:**
- Modify: `CLAUDE.md` (Layout section, after the `parts/hosts/<host>.nix` bullet)

- [ ] **Step 1: Add this bullet, matching the neighbouring style:**
  `` - `hosts/<host>/`: per-host sops files (`.sops.yaml`, encrypted `secrets.yaml`, examples), `cobalto/deploy_key.pub` and `infinix/nix-on-droid.nix`. It is not a NixOS module tree: NixOS host config lives in `parts/`. ``
- [ ] **Step 2: Verify.** Read the Layout section. Expected: the bullet is present, no dashes, and no claim that `hosts/common/` exists.
- [ ] **Step 3: Commit** `docs(claude): document top-level hosts directory`.

### Task 4: Delete stale review prompt

**Files:**
- Delete: `docs/review-cobalto-impermanence.md`

- [ ] **Step 1: Run `git rm docs/review-cobalto-impermanence.md`.**
- [ ] **Step 2: Verify.** Run `grep -rn 'review-cobalto-impermanence' . --exclude-dir=.git`. Expected: only this plan and the spec.
- [ ] **Step 3: Commit** `docs: remove stale cobalto impermanence review prompt`.

### Task 5: Remove dashes from docs

**Files:**
- Modify: `docs/media-migration-runbook.md` (headings at lines 8, 67, 125, 148, 230), plus any other hit

- [ ] **Step 1: Scan.** Run `grep -rnP '—|–' docs CLAUDE.md README* --exclude-dir=superpowers`. Expected: the five runbook headings, possibly more.
- [ ] **Step 2: Replace.** In each `## Phase N — Title` heading, replace ` — ` with `: `. For other hits, use a comma, colon or parentheses that keeps the sentence correct.
- [ ] **Step 3: Verify.** Re-run the scan. Expected: no output. Run `grep -rn '](#' docs`. Expected: no link targets a changed heading.
- [ ] **Step 4: Commit** `docs: replace em dashes with colons in runbook headings`.

### Task 6: Final check

- [ ] **Step 1:** Run `git add -A && nix flake check --no-build`. Expected: exits 0.
- [ ] **Step 2:** Push the branch and open a PR with `gh`. Do not merge.

---

Self-review: tasks 1 to 5 map to spec items 1 to 5, and task 6 covers the spec's verification section. No host build is needed because nothing under `parts/` changes.
