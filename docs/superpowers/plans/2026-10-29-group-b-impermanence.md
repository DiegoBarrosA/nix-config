# Group B Impermanence Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist transmission and zennotes state on cobalto and docker state on rubi, and delete the dead `system-impermanence` module.

**Architecture:** Each fix is a small edit to a host `impermanence.nix` list, or a file deletion. Nix has no unit tests here, so each task is verified by evaluating the persisted directory list before and after the change.

**Tech Stack:** Nix flakes, flake-parts, the impermanence module.

**Spec:** `docs/superpowers/specs/2026-10-29-group-b-impermanence.md`

## Global Constraints

- Stage changed files with `git add` before any `nix` command.
- Do not reformat the odd indentation in the two host impermanence files.
- One commit per finding, conventional messages, each ending with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Do not change the `nixpkgs` pin. Do not deploy.
- No em dashes or en dashes in any text.

## Review Focus

- Persist target created as `root:root`: the cobalto entries must use the attrset form with user and group.
- A servarr path persisted again: nothing under `/nix/storage` may appear in any persisted list.
- A host still imports the deleted module: both host builds must evaluate.

---

### Task 1: Persist transmission on cobalto

**Files:**
- Modify: `parts/nixos/hosts/cobalto/impermanence.nix` (`directories` list, before the `/var/backup/postgresql` entry)

**Interfaces:**
- Produces: a `directories` entry with `directory = "/var/lib/transmission"`.

- [ ] **Step 1: Record the failing check**

Run: `nix eval .#nixosConfigurations.cobalto.config.environment.persistence.\"/nix/persist\".directories --apply 'ds: map (d: d.directory) ds' --json | grep -c /var/lib/transmission`
Expected: `0`

- [ ] **Step 2: Add the entry**

Add an attrset with `directory = "/var/lib/transmission"; user = "media"; group = "media"; mode = "0700";`. Check how the pinned nixpkgs `services.transmission` creates its home (`nix eval` or read the module source). If it sets a different mode, use that mode and note it in the commit body.

- [ ] **Step 3: Verify**

Re-run the Step 1 command after `git add`. Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add parts/nixos/hosts/cobalto/impermanence.nix
git commit -m "fix(cobalto): persist transmission state"
```

### Task 2: Persist zennotes on cobalto

**Files:**
- Modify: `parts/nixos/hosts/cobalto/impermanence.nix` (same list, next to the transmission entry)

- [ ] **Step 1: Record the failing check**

Same command as Task 1 with `/var/lib/zennotes`. Expected: `0`.

- [ ] **Step 2: Add the entry**

Attrset with `directory = "/var/lib/zennotes"; user = "diego"; group = "users"; mode = "0755";`.

- [ ] **Step 3: Verify**

Re-run after `git add`. Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add parts/nixos/hosts/cobalto/impermanence.nix
git commit -m "fix(cobalto): persist zennotes state"
```

### Task 3: Persist docker on rubi

**Files:**
- Modify: `parts/nixos/hosts/rubi/impermanence.nix` (add `"/var/lib/docker"` after `"/var/lib/cups"`)

- [ ] **Step 1: Record the failing check**

Run: `nix eval .#nixosConfigurations.rubi.config.environment.persistence.\"/nix/persist\".directories --apply 'ds: map (d: d.directory) ds' --json | grep -c /var/lib/docker`
Expected: `0`

- [ ] **Step 2: Add the plain string entry**

- [ ] **Step 3: Verify**

Re-run after `git add`. Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add parts/nixos/hosts/rubi/impermanence.nix
git commit -m "fix(rubi): persist docker state"
```

### Task 4: Delete the dead module

**Files:**
- Delete: `parts/nixos/optional/system/impermanence.nix`

- [ ] **Step 1: Confirm nothing uses it**

Run: `grep -rn "system-impermanence" parts flake.nix`
Expected: only the definition line in the file itself.

- [ ] **Step 2: Remove it**

Run: `git rm parts/nixos/optional/system/impermanence.nix`

- [ ] **Step 3: Verify**

Run: `grep -rn "system-impermanence" parts flake.nix`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor: remove dead system-impermanence module"
```

### Task 5: Final verification

- [ ] **Step 1:** `nix flake check --no-build`. Expected: exit 0.
- [ ] **Step 2:** `nix build .#nixosConfigurations.cobalto.config.system.build.toplevel`. Expected: exit 0.
- [ ] **Step 3:** `nix build .#nixosConfigurations.rubi.config.system.build.toplevel`. Expected: exit 0.
- [ ] **Step 4:** Evaluate both persisted lists and check that no entry starts with `/nix/storage`.
