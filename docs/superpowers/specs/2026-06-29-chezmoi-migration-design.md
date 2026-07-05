# chezmoi Dotfiles Migration — Design

**Date:** 2026-06-29
**Author:** Jóni Oliveira
**Status:** Approved (design phase)

## Problem

The current dotfiles repo is an Ansible playbook that has drifted ~2 years behind
the actual machine. It describes an Intel Mac (`/usr/local` hardcoded), oh-my-zsh +
spaceship prompt, nvm/tfenv, docker/vagrant/virtualbox — none of which match the
live machine, which runs Apple Silicon (`/opt/homebrew`), starship, mise, and a
modern Rust-CLI stack (eza, bat, ripgrep, delta, dust, duf, procs, zoxide, fzf).

Root cause of the drift: Ansible **copies** a static `.zshrc` into place, so direct
edits to `~/.zshrc` never flow back to the repo. The repo is not a source of truth.

If the current repo were run on a new Mac today, it would produce a broken,
out-of-date setup.

## Goals

1. Rebuild the repo so it faithfully reflects the **current** machine and can
   restore/provision any of 4 machines.
2. Eliminate drift structurally — edits to managed files must flow back to the repo.
3. Support **4 machines**: 2 personal, 2 work, with controlled divergence.
4. Keep **zero secrets in git** (work tokens, AWS creds) via 1Password.

## Non-Goals

- Full unattended fleet provisioning (overkill for 4 personal/work Macs).
- Syncing application auth state (e.g. Claude Code login tokens) — handled manually
  per machine.
- Cross-platform (Linux) support — all 4 machines are macOS, likely all Apple Silicon.

## Tool Choice

**chezmoi** (replacing Ansible). Chosen over GNU Stow because the 4 machines split
2 personal / 2 work and need *different* configs from one repo — exactly the
heterogeneity case where chezmoi's templating earns its keep. Secrets come from
**1Password** via the `op` CLI, resolved at `chezmoi apply` time, so nothing secret
is committed.

## Architecture

One chezmoi-managed repo. A single template variable `isWork` (prompted on
`chezmoi init`) drives all work/personal divergence.

```
~/.local/share/chezmoi/                    # the repo, git remote: dotfiles
├── .chezmoi.toml.tmpl                      # prompts isWork on init; sets template data
├── .chezmoiignore                          # never-manage list (Claude auth, caches)
├── dot_zshrc.tmpl                          # current ~/.zshrc, templated
├── dot_gitconfig.tmpl                      # personal identity + includeIf for ~/work/
├── dot_gitconfig-work.tmpl                 # work email/signing, included conditionally
├── private_dot_ssh/
│   └── config.tmpl                         # gitlab.company.com host block when isWork
├── dot_config/
│   ├── starship.toml                       # tuned starship config (currently default)
│   └── mise/config.toml                    # node, pnpm (from live machine)
├── Brewfile.tmpl                           # shared + work-only + personal-only sections
├── dot_macos                               # macOS defaults script (kept, review before run)
└── run_once_before_install-tools.sh.tmpl   # bootstrap: brew, brew bundle
```

Naming conventions: `dot_` → `.`; `private_` → 0600 perms (used for `~/.ssh`);
`run_once_before_` → idempotent bootstrap script run before file application;
`.tmpl` → Go-template processed.

## Divergence Handling

| Concern | Mechanism |
|---|---|
| Git identity | `dot_gitconfig.tmpl` sets **personal** identity globally (the default for `~/dev/` and everywhere else); `includeIf "gitdir:~/workspace/"` overlays the **work** email/signing for repos under `~/workspace/`, and is only present when `isWork`. Personal repos live in `~/dev/`, work repos in `~/workspace/`. No manual switching. |
| GitLab SSH | `private_dot_ssh/config.tmpl` adds a `gitlab.company.com` Host block (+ IdentityFile) only `{{ if .isWork }}`. |
| glab CLI | In `Brewfile.tmpl` under a `{{ if .isWork }}` block. |
| Claude Code logins | **Not managed.** `~/.claude/settings.json` is synced (shared config); auth token is in `.chezmoiignore`. Sign in manually per machine. |
| Secrets (work AWS, tokens) | `{{ onepasswordRead "op://Work/item/field" }}` in templates; resolved at apply, never in git. |
| Personal-only apps (spotify, steam) | `Brewfile.tmpl` under `{{ if not .isWork }}`. |

## Brew — captured from reality

The `Brewfile` is generated from the **actual** installed list, not the stale
Ansible vars.

**Shared base (formulae):** git, gh, eza, bat, ripgrep, fd, git-delta, dust, duf,
procs, fzf, zoxide, mise, uv, htop, tree, yq, kubernetes-cli, kubectx, helm,
opentofu, tflint, tfsec, trivy, infracost, podman, tailscale, cloudflared, hcloud,
ollama, libpq, ffmpeg.

**Shared casks:** raycast, ghostty, visual-studio-code, clipy, podman-desktop,
freelens, spotify.

**Work-only:** glab (+ work VPN client if needed).

**Personal-only:** steam, and any media/game apps.

**Dropped (dead / uninstalled):** vagrant, virtualbox, minikube, okteto, nmap,
tunnelblick, zoomus, microsoft-office, microsoft-auto-update, hub (→ gh), asdf
(→ mise), terraform/tfenv (→ opentofu), nvm (→ mise), docker desktop (→ podman),
discord (unless wanted), notion (unless wanted).

**Kept (shared cask):** postman.

> Final inclusion of ambiguous casks (discord, notion) to be confirmed during
> implementation against what is actually installed.

## Bootstrap & Idempotency

New machine:
1. Install chezmoi + 1Password CLI (`op`).
2. Sign into 1Password (`op signin`).
3. `chezmoi init --apply git@github.com:jonioliveira/dotfiles.git`
   - prompts `isWork`.
   - `run_once_before_install-tools.sh.tmpl` installs Homebrew if missing, then
     runs `brew bundle --file=~/.local/share/chezmoi/Brewfile`.

`op` must be installed and signed in **before** apply, or secret-bearing templates
fail. The bootstrap script installs `op` early if missing.

All `run_once_` scripts are idempotent and safe to re-run.

## Migration & Verification

- Build the new chezmoi repo on the `chezmoi-migration` branch; keep the old Ansible
  layout reachable on `master` as a backup until verified.
- Before any home-dir change: `chezmoi apply --dry-run` and `chezmoi diff` to show
  exactly what would change. Nothing is overwritten blind.
- Verify `brew bundle check --file=Brewfile` passes after generating the Brewfile.
- Verify the rendered `~/.zshrc` matches the current working one (modulo template
  parameterization) before applying.

## Machine Cleanup (optional, separate from repo)

Independent of the repo rebuild, the live machine can be tidied:
- Remove orphaned `asdf` (mise replaces it) and deprecated `hub` (gh replaces it).
- `brew upgrade` the 29 outdated formulae, then `brew cleanup` / `brew autoremove`.
- Add the tuned `starship.toml` (currently running default starship with no config).

## Open Questions / To Confirm During Implementation

1. Exact `op://` paths for work secrets (vault + item names).
2. Work GitLab host (`gitlab.company.com` placeholder) and IdentityFile path.
3. Final cask list for ambiguous apps (discord, notion).
4. Whether to run the old `.macos` defaults script as-is or prune it first.

## Resolved Conventions

- **Personal repos:** `~/dev/`. **Work repos:** `~/workspace/`.
- Git default identity = personal; work identity overlaid via
  `includeIf "gitdir:~/workspace/"` only on work machines.
- Shell jump aliases updated to match: `dev` → `cd ~/dev`, `work` → `cd ~/workspace`
  (replacing the old `wk`/`cmy` aliases that pointed at `~/Workspace/cloudmobility`).
- Postman kept as a shared cask.
