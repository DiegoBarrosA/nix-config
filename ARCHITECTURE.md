# Architecture

This configuration is split across three repositories. The rule of the split:

> **nix-config**: anything a stranger may read; **nix-ai-tooling**: anything a
> stranger may reuse; **nix-private-config**: anything that names a customer or
> holds a secret.

## The three repositories

| Repo | Visibility | Contents |
| --- | --- | --- |
| `nix-config` (this repo) | **public** | Hosts `cobalto`, `granate`, `rubi` (NixOS), `lonsdaleita` (nix-on-droid), `lapislazuli` (home-manager on macOS); shared modules; per-user features |
| [`nix-ai-tooling`](https://github.com/DiegoBarrosA/nix-ai-tooling) | **public** flake (`github:DiegoBarrosA/nix-ai-tooling`) | Seven reusable home-manager AI modules: `mcp-config`, `opencode-config`, `claude-code-config`, `claude-desktop-config`, `cursor-config`, `antigravity-config`, `ai-skills` |
| `nix-private-config` | **private** (`git+ssh`) | `customers/<name>/` (one directory per engagement) plus `personal/` (private but not customer-bound), plus the customer's private MCP-server packages |

```mermaid
graph TD
    subgraph pub["Public"]
        AIT["nix-ai-tooling<br/>reusable HM AI modules"]
        NC["nix-config<br/>hosts · home · shared modules"]
    end
    subgraph priv["Private (git+ssh)"]
        PC["nix-private-config<br/>customers/ · personal/ · MCP pkgs"]
    end

    AIT -->|"homeManagerModules.*<br/>(mcp / opencode / claude-* / cursor / …)"| NC
    PC -->|"neutral exports:<br/>workMcpConfig, workExtras,<br/>nixosModules.work, secretFiles"| NC
    NC -.->|"flake input (?ref=employer-cleanup)"| PC

    classDef pubc fill:#a8d5a2,color:#000
    classDef privc fill:#e8a87c,color:#000
    class AIT,NC pubc
    class PC privc
```

## Repo layout (nix-config)

- `flake.nix` — inputs + outputs (see below).
- `lib/` — `mkHost` / `mkHome` helpers that assemble the flake outputs.
- `hosts/common/global` — config shared by every host.
- `hosts/common/optional/{ai,apps,desktop,media,network,system}` — opt-in modules grouped by domain.
- `hosts/common/users/diego` — user-level system config.
- `hosts/{cobalto,granate,rubi,lonsdaleita}` — per-host entry points.
- `modules/{nixos,home-manager}` — custom option-providing modules.
- `home/diego/features/{ai,cli,desktop}` — per-user feature toggles; `home/diego/<host>.nix` — per-host home entry points.
- `pkgs/`, `overlays/` — custom packages and nixpkgs overlays.
- `docs/` — Jekyll site published to GitHub Pages.

## Flake inputs & outputs

```mermaid
graph LR
    subgraph in["Key inputs"]
        NP["nixpkgs<br/>(unstable)"]
        HM["home-manager"]
        SOPS["sops-nix"]
        STY["stylix"]
        DEP["deploy-rs"]
        DSK["disko"]
        IMP["impermanence"]
        NOD["nix-on-droid"]
        AIT2["ai-tooling"]
        PC2["private-config"]
    end
    subgraph out["Outputs"]
        NOS["nixosConfigurations<br/>cobalto · granate · rubi"]
        HC["homeConfigurations<br/>diego@{cobalto,rubi,lapislazuli}"]
        NDC["nixOnDroidConfigurations<br/>lonsdaleita"]
        PKG["packages · overlays · devShells"]
        DPL["deploy (deploy-rs)<br/>cobalto · granate"]
    end
    NP --> out
    HM --> HC
    NOD --> NDC
    AIT2 --> HC
    PC2 --> HC
    PC2 --> NOS
    NOS --> DPL
    classDef i fill:#7eb8da,color:#000
    classDef o fill:#c9a0dc,color:#000
    class NP,HM,SOPS,STY,DEP,DSK,IMP,NOD,AIT2,PC2 i
    class NOS,HC,NDC,PKG,DPL o
```

`mkHost system hostname { desktop ? null }` builds a `nixosConfigurations` entry;
`mkHome system entrypoint extraModules { desktop ? null }` builds a
`homeConfigurations` entry, threading `private-config` in as `privateConfig` and
importing `workMcpConfig`. Most sibling inputs (`home-manager`, `sops-nix`,
`disko`, `deploy-rs`, …) `follow` nixpkgs so the whole tree stays on one
revision.

## The customer contract

Each `customers/<name>/default.nix` in the private repo implements one contract:
`nixosModule`, `homeModules.{mcpConfig,claudeDesktopMcpConfig,omnistation}`,
`workProfile`, `opencodeConfig`, `openclawConfig`, `skills`, `secretEnv`,
`secretFiles`, `providerLabel`, `providerId`, `inferenceEnvVar`.

The private flake selects one customer via its `activeCustomer` knob and
re-exports everything under **neutral names** — the only names this repo is
allowed to reference: `homeManagerModules.{workMcpConfig,workClaudeDesktopMcpConfig,workExtras}`,
`nixosModules.work`, `workProfile`, `workSecretEnv`, `workSkills`,
`workProviderLabel`, `workProviderId`, `workInferenceEnvVar`, `secretFiles`,
`opencodeConfig`, `openclawConfig`. This repo therefore contains no
customer-named literals; everything customer-specific flows in through the
`private-config` flake input.

> Runtime env-var names and `/run/secrets/*` paths for work MCP instances are
> deliberately neutral too (`WORK_JIRA_A_*`, `WORK_CONFLUENCE_A_*`,
> `/run/secrets/work-jira-a-*`). The private repo maps these back to the real
> encrypted yaml keys via a sops-nix `key` alias, so no employer-internal
> instance codenames appear here.

## Secrets

Secrets are sops-encrypted (age) and split across two tiers:

- **Host/system secrets** live *in this repo* at `hosts/<host>/secrets.yaml`
  (encrypted). They cover system-level material (`diego-password`,
  `tailscale-key`, `luks-passphrase`, …). Base wiring is in
  `hosts/common/optional/system/sops-base.nix`, which sets
  `defaultSopsFile = hosts/<hostname>/secrets.yaml` and decrypts with a **static
  age key** at `/nix/persist/var/lib/sops-nix/key.txt` (`age.generateKey = false`).
- **Work & personal secrets** live *only in the private repo*, under
  `customers/<name>/secrets/` and `personal/secrets/`, and reach this repo
  through `private-config`'s `secretFiles` export.

```mermaid
graph LR
    K["/nix/persist/var/lib/<br/>sops-nix/key.txt<br/>(age private key)"]
    HS["hosts/&lt;host&gt;/secrets.yaml<br/>(this repo, encrypted)"]
    PS["private-config<br/>customers/·personal/ secrets<br/>(encrypted)"]
    RS["/run/secrets/*"]
    HS -->|decrypt| RS
    PS -->|decrypt| RS
    K --> RS
    classDef k fill:#e8a87c,color:#000
    classDef s fill:#f0d58c,color:#000
    classDef r fill:#a8d5a2,color:#000
    class K k
    class HS,PS s
    class RS r
```

A plaintext `hosts/rubi/secrets.yaml.template` documents the required keys for a
fresh install; only the encrypted `secrets.yaml` is ever meant to be committed
(enforced by `.gitignore`).

## New engagement checklist

1. Create `customers/<name>/` in the private repo implementing the contract above.
2. Flip `activeCustomer = "<name>";` in the private repo's `flake.nix`.
3. Add sops-encrypted secrets under `customers/<name>/secrets/`.
4. In this repo: `nix flake lock --update-input private-config`.

## CI/CD

GitHub Actions workflows in `.github/workflows/`:

- `coderabbit-review.yml` — AI code review (CodeRabbit) on pull requests.
- `jekyll.yml` — builds & publishes the `docs/` site to GitHub Pages.
- `build-iso.yml` — builds a NixOS installer ISO.

Remote deployment is handled out-of-band by **deploy-rs** (`nix run .#deploy`),
which targets `cobalto` (over Tailscale) and `granate` (over its public IP).

## TEMP

The `private-config` input is currently pinned to the private repo's cleanup
branch (`?ref=employer-cleanup` in `flake.nix`). Drop the ref when the cleanup
branches merge to their default branches.
