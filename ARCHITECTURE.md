# Architecture

This configuration is split across three repositories. The rule of the split:

> **nix-config**: anything a stranger may read; **nix-ai-tooling**: anything a
> stranger may reuse; **nix-private-config**: anything that names a customer or
> holds a secret.

## The three repositories

| Repo | Visibility | Contents |
| --- | --- | --- |
| `nix-config` (this repo) | public | Hosts `cobalto`, `granate`, `rubi`, `lonsdaleita`; home-manager config; personal modules |
| [`nix-ai-tooling`](https://github.com/DiegoBarrosA/nix-ai-tooling) | public flake (`github:DiegoBarrosA/nix-ai-tooling`) | Six reusable home-manager AI modules: `mcp-config`, `opencode-config`, `claude-code-config`, `cursor-config`, `antigravity-config`, `ai-skills` |
| `nix-private-config` | private (`git+ssh`) | `customers/<name>/` (one directory per engagement) plus `personal/` (private but not customer-bound) |

## Repo layout (nix-config)

- `hosts/common/global` — config shared by every host.
- `hosts/common/optional/{media,apps,network,ai,desktop,system}` — opt-in modules grouped by domain.
- `lib/` — `mkHost` / `mkHome` helpers that build the flake outputs.
- `modules/`, `home/diego/features/` — custom modules and per-user feature toggles.

## The customer contract

Each `customers/<name>/default.nix` in the private repo implements one contract:
`nixosModule`, `homeModules.{mcpConfig,omnistation}`, `workProfile`,
`opencodeConfig`, `openclawConfig`, `skills`, `secretEnv`, `secretFiles`,
`providerLabel`, `providerId`, `inferenceEnvVar` (and optionally
`codexProfile`).

The private flake selects one customer via its `activeCustomer` knob and
re-exports everything under **neutral names** — the only names this repo is
allowed to reference: `homeManagerModules.{workMcpConfig,workExtras}`,
`nixosModules.work`, `workProfile`, `workSecretEnv`, `workSkills`,
`workProviderLabel`, `workProviderId`, `workInferenceEnvVar`, `secretFiles`,
`opencodeConfig`, `openclawConfig`. This repo therefore contains no
customer-named literals; everything customer-specific flows in through the
`private-config` flake input.

## Secrets

Secrets live only in the private repo, under `customers/<name>/secrets/`
(customer-bound) and `personal/secrets/`, encrypted with sops. Hosts decrypt
with an age key at `/nix/persist/var/lib/sops-nix/key.txt`
(see `hosts/common/optional/system/sops-base.nix`).

## New engagement checklist

1. Create `customers/<name>/` in the private repo implementing the contract above.
2. Flip `activeCustomer = "<name>";` in the private repo's `flake.nix`.
3. Add sops-encrypted secrets under `customers/<name>/secrets/`.
4. In this repo: `nix flake lock --update-input private-config`.

## CI/CD (added in this branch)

- `check.yml` — verifies the flake builds on every push.
- `deploy.yml` — deploys `cobalto` via Tailscale + deploy-rs on pushes to `main`.

## TEMP

The `private-config` input is currently pinned to the private repo's cleanup
branch (`?ref=...` in `flake.nix`). Drop the ref when both cleanup branches
merge.
