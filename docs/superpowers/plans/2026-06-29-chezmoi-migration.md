# chezmoi Dotfiles Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stale Ansible dotfiles repo with a chezmoi-managed repo that reflects the current Apple Silicon machine and provisions 4 machines (2 personal, 2 work) with 1Password-backed secrets.

**Architecture:** A single chezmoi source repo. One template variable `isWork` (prompted on `chezmoi init`) drives all work/personal divergence. Homebrew is managed declaratively via a templated `Brewfile`. Secrets resolve from 1Password (`op` CLI) at apply time, so nothing secret is committed. The work tree is built on branch `chezmoi-migration`; the old Ansible layout stays on `master` as backup.

**Tech Stack:** chezmoi, Homebrew (`brew bundle`), 1Password CLI (`op`), Go templates, zsh.

## Global Constraints

- Target platform: macOS, Apple Silicon (`/opt/homebrew`). No Intel/Linux branches required.
- Zero secrets committed to git — secrets resolve via `onepasswordRead` at apply time.
- `op` must be installed and signed in before any secret-bearing template is applied.
- chezmoi source files use prefix conventions: `dot_` → `.`, `private_` → 0600 perms, `run_once_before_` → idempotent pre-apply script, `.tmpl` → Go-template processed.
- Personal repos live in `~/dev/`; work repos in `~/workspace/`. Git default identity = personal; work identity overlaid via `includeIf "gitdir:~/workspace/"`, present only when `isWork`.
- Every change is verified with `chezmoi diff` / `chezmoi execute-template` before `chezmoi apply` touches the home directory. Nothing is overwritten blind.
- Verification replaces unit tests throughout: chezmoi has no test harness, so each task's "test" is a deterministic command with expected output.

---

## File Structure

All paths are inside the chezmoi source dir, which we will point at the existing repo working tree (`~/workspace/dotfiles`) via `chezmoi --source`.

| File | Responsibility |
|---|---|
| `.chezmoi.toml.tmpl` | Prompt `isWork` on init; set template data + 1Password config |
| `.chezmoiignore` | Files chezmoi must never manage (Claude auth, caches) |
| `dot_zshrc.tmpl` | Templated shell config, derived from current `~/.zshrc` |
| `dot_gitconfig.tmpl` | Personal git identity + `includeIf` for work |
| `dot_gitconfig-work.tmpl` | Work email/signing, conditionally included |
| `private_dot_ssh/config.tmpl` | GitLab host block when `isWork` |
| `dot_config/starship.toml` | Tuned starship prompt config |
| `dot_config/mise/config.toml` | mise tool versions (node) |
| `Brewfile.tmpl` | Shared + work-only + personal-only brew packages |
| `dot_macos` | macOS defaults script (kept, not auto-run) |
| `run_once_before_10-install-tools.sh.tmpl` | Bootstrap: Homebrew + `op` + `brew bundle` |
| `README.md` | New bootstrap instructions (replaces Ansible README) |

Files removed from the repo: `playbook.yml`, `hosts`, `start.sh`, `roles/**`, `dotfiles/.zshrc` (old), `dotfiles/iterm2_profiles.json` (iTerm2 no longer used — Ghostty), old `dotfiles/.macos` (moved to source root as `dot_macos`).

---

### Task 1: Install chezmoi + 1Password CLI, point source at the repo

**Files:**
- None created yet; this task installs tooling and initializes chezmoi against the existing repo working tree.

**Interfaces:**
- Produces: a working `chezmoi` binary whose source dir is `~/workspace/dotfiles`; `op` CLI available.

- [ ] **Step 1: Install chezmoi, op, and fd via brew**

```bash
brew install chezmoi fd
brew install --cask 1password-cli
```

- [ ] **Step 2: Verify the tools are present**

Run:
```bash
chezmoi --version && op --version && fd --version
```
Expected: three version strings, no "command not found".

- [ ] **Step 3: Point chezmoi's source at the existing repo (do NOT run `chezmoi init <url>` — that would clone elsewhere)**

```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
sourceDir = "/Users/jonioliveira/workspace/dotfiles"
EOF
```

- [ ] **Step 4: Verify chezmoi sees the repo as its source**

Run: `chezmoi source-path`
Expected: `/Users/jonioliveira/workspace/dotfiles`

- [ ] **Step 5: No commit**

This task only installs environmental tooling (`chezmoi`, `op`, `fd`) and writes `~/.config/chezmoi/chezmoi.toml` outside the repo. Nothing in the repo changed, so there is nothing to commit. Proceed to Task 2.

---

### Task 2: Create `.chezmoi.toml.tmpl` (isWork prompt) and `.chezmoiignore`

**Files:**
- Create: `~/workspace/dotfiles/.chezmoi.toml.tmpl`
- Create: `~/workspace/dotfiles/.chezmoiignore`

**Interfaces:**
- Produces: template variable `.isWork` (bool) available to all `.tmpl` files; `.chezmoiignore` excluding Claude auth + caches.

- [ ] **Step 1: Write `.chezmoi.toml.tmpl`**

```toml
{{- $isWork := promptBoolOnce . "isWork" "Is this a work machine" -}}
[data]
    isWork = {{ $isWork }}

[onepassword]
    prompt = false
```

- [ ] **Step 2: Write `.chezmoiignore`**

```
# Claude Code auth state — sign in manually per machine
.claude/.credentials.json
.claude/statsig
.claude/sessions
.claude/projects

# Caches / generated
.zcompdump*
.zsh/**/*.zwc

# Plan/spec docs live in the repo but are not home-dir files
docs/
README.md
```

- [ ] **Step 3: Verify the toml template renders for a personal machine**

Run: `chezmoi execute-template --init --promptBool isWork=false < .chezmoi.toml.tmpl`
Expected output contains: `isWork = false`

- [ ] **Step 4: Verify it renders for a work machine**

Run: `chezmoi execute-template --init --promptBool isWork=true < .chezmoi.toml.tmpl`
Expected output contains: `isWork = true`

- [ ] **Step 5: Commit**

```bash
git add .chezmoi.toml.tmpl .chezmoiignore
git commit -m "feat: add chezmoi config template with isWork prompt and ignore list"
```

---

### Task 3: Author `dot_zshrc.tmpl` from the current shell config

**Files:**
- Create: `~/workspace/dotfiles/dot_zshrc.tmpl`
- Reference: current `~/.zshrc` (source of truth for content)

**Interfaces:**
- Consumes: `.isWork` from Task 2.
- Produces: a rendered `~/.zshrc` byte-identical to the current working one for a personal machine, plus a work-only GitLab/`glab` block when `isWork`.

- [ ] **Step 1: Seed the template from the live file**

```bash
cp ~/.zshrc ~/workspace/dotfiles/dot_zshrc.tmpl
```

- [ ] **Step 2: Replace machine-specific absolute paths and add the work block**

Edit `dot_zshrc.tmpl`:
- Replace hardcoded `/Users/jonioliveira` occurrences (LM Studio, bun, pnpm paths) with `{{ .chezmoi.homeDir }}`.
- Update the navigation/jump aliases to the new convention. Replace any `wk`/`cmy`/`cmyp` aliases with:

```sh
alias dev="cd ~/dev"
alias work="cd ~/workspace"
```

- Add this block near the kubectl section (work-only tooling), guarded by the template:

```sh
{{ if .isWork -}}
# Work-only: glab completion
if command -v glab >/dev/null 2>&1; then
  source <(glab completion -s zsh)
fi
{{- end }}
```

- [ ] **Step 3: Render for personal machine and diff against the live file**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=false \
  < dot_zshrc.tmpl > /tmp/zshrc.personal
diff <(sed "s#/Users/jonioliveira#$HOME#g" ~/.zshrc) /tmp/zshrc.personal
```
Expected: only the intentional alias changes (`dev`/`work`) and the absent work block differ — no unexpected drift. Review the diff and confirm it is exactly the intended set of changes.

- [ ] **Step 4: Render for work machine and confirm the glab block appears**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=true \
  < dot_zshrc.tmpl | grep -A2 "glab completion"
```
Expected: the `glab completion` block is present.

- [ ] **Step 5: Commit**

```bash
git add dot_zshrc.tmpl
git commit -m "feat: template zshrc with portable paths and work-only glab block"
```

---

### Task 4: Git identity templates (`dot_gitconfig.tmpl` + work overlay)

**Files:**
- Create: `~/workspace/dotfiles/dot_gitconfig.tmpl`
- Create: `~/workspace/dotfiles/dot_gitconfig-work.tmpl`

**Interfaces:**
- Consumes: `.isWork`.
- Produces: rendered `~/.gitconfig` with personal identity default; on work machines, an `includeIf "gitdir:~/workspace/"` pointing at `~/.gitconfig-work`, which sets the work email. Work email comes from 1Password.

- [ ] **Step 1: Write `dot_gitconfig.tmpl`**

```ini
[user]
    name = Jóni Oliveira
    email = joni@jonioliveira.dev

[init]
    defaultBranch = main

[pull]
    rebase = true

[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true

[push]
    autoSetupRemote = true
{{ if .isWork }}
[includeIf "gitdir:~/workspace/"]
    path = ~/.gitconfig-work
{{- end }}
```

- [ ] **Step 2: Write `dot_gitconfig-work.tmpl` (work identity, email from 1Password)**

```ini
[user]
    email = {{ onepasswordRead "op://Work/git/email" }}
```

> Note: the `op://Work/git/email` path is a placeholder vault/item to confirm during execution. If the work email is not sensitive, it may be hardcoded instead and 1Password dropped for this field.

- [ ] **Step 3: Render personal gitconfig and confirm no work include**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=false < dot_gitconfig.tmpl
```
Expected: contains `email = joni@jonioliveira.dev`; does NOT contain `includeIf`.

- [ ] **Step 4: Render work gitconfig and confirm the include appears**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=true < dot_gitconfig.tmpl | grep includeIf
```
Expected: `[includeIf "gitdir:~/workspace/"]` present.

- [ ] **Step 5: Commit**

```bash
git add dot_gitconfig.tmpl dot_gitconfig-work.tmpl
git commit -m "feat: template git identity with personal default and work overlay"
```

---

### Task 5: SSH config template (GitLab host, work-only)

**Files:**
- Create: `~/workspace/dotfiles/private_dot_ssh/config.tmpl`

**Interfaces:**
- Consumes: `.isWork`.
- Produces: rendered `~/.ssh/config` (mode 0600 via `private_` prefix). On work machines it adds a `gitlab.<company>.com` Host block with a dedicated IdentityFile.

- [ ] **Step 1: Write `private_dot_ssh/config.tmpl`**

```
# Managed by chezmoi. Do not edit ~/.ssh/config directly.

Host github.com
    User git
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
{{ if .isWork }}
Host gitlab.company.com
    User git
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519_work
{{- end }}
```

> Note: replace `gitlab.company.com` and the work key filename with the real values during execution.

- [ ] **Step 2: Render personal ssh config and confirm GitLab block is absent**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=false < private_dot_ssh/config.tmpl
```
Expected: contains `Host github.com`; does NOT contain `gitlab`.

- [ ] **Step 3: Render work ssh config and confirm GitLab block present**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=true < private_dot_ssh/config.tmpl | grep gitlab
```
Expected: `Host gitlab.company.com` present.

- [ ] **Step 4: Verify chezmoi assigns 0600 to the target**

Run: `chezmoi cat ~/.ssh/config >/dev/null && chezmoi target-path ~/.ssh/config`
Then check the source attributes render private:
Run: `chezmoi managed | grep '.ssh/config'`
Expected: `.ssh/config` listed as managed. (Mode is enforced by the `private_` prefix on apply.)

- [ ] **Step 5: Commit**

```bash
git add private_dot_ssh/config.tmpl
git commit -m "feat: template ssh config with work-only gitlab host"
```

---

### Task 6: `Brewfile.tmpl` from the real installed set

**Files:**
- Create: `~/workspace/dotfiles/Brewfile.tmpl`

**Interfaces:**
- Consumes: `.isWork`.
- Produces: a `Brewfile` consumable by `brew bundle`. Shared base reflects the actual `brew leaves` / `brew list --cask` output; work block adds `glab`; personal block adds personal-only casks.

- [ ] **Step 1: Write `Brewfile.tmpl`**

```ruby
# Managed by chezmoi. Edit Brewfile.tmpl in the dotfiles repo, not the rendered file.

# --- Shared formulae ---
brew "git"
brew "gh"
brew "chezmoi"
brew "mise"
brew "uv"
brew "fzf"
brew "zoxide"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"
brew "git-delta"
brew "dust"
brew "duf"
brew "procs"
brew "htop"
brew "tree"
brew "yq"
brew "ffmpeg"
brew "libpq"

# Kubernetes
brew "kubernetes-cli"
brew "kubectx"
brew "helm"

# Infra / cloud
brew "opentofu"
brew "tflint"
brew "tfsec"
brew "trivy"
brew "infracost"
brew "awscli"
brew "hcloud"
brew "tailscale"
brew "cloudflared"

# Containers / AI
brew "podman"
brew "ollama"

# --- Shared casks ---
cask "ghostty@tip"
cask "visual-studio-code"
cask "raycast"
cask "clipy"
cask "podman-desktop"
cask "freelens"
cask "1password-cli"

{{ if .isWork }}
# --- Work-only ---
brew "glab"
{{- end }}

{{ if not .isWork }}
# --- Personal-only ---
cask "spotify"
{{- end }}
```

- [ ] **Step 2: Render the personal Brewfile**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=false < Brewfile.tmpl > /tmp/Brewfile.personal
grep -q 'cask "spotify"' /tmp/Brewfile.personal && ! grep -q 'glab' /tmp/Brewfile.personal && echo OK
```
Expected: `OK`.

- [ ] **Step 3: Render the work Brewfile**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=true < Brewfile.tmpl > /tmp/Brewfile.work
grep -q 'brew "glab"' /tmp/Brewfile.work && ! grep -q 'spotify' /tmp/Brewfile.work && echo OK
```
Expected: `OK`.

- [ ] **Step 4: Verify the personal Brewfile matches the current machine**

Run: `brew bundle check --file=/tmp/Brewfile.personal`
Expected: `The Brewfile's dependencies are satisfied.` (If it reports missing items, those are tools to either install or remove from the Brewfile — reconcile so the list matches reality before committing.)

- [ ] **Step 5: Commit**

```bash
git add Brewfile.tmpl
git commit -m "feat: declarative Brewfile from real installed packages with work/personal splits"
```

---

### Task 7: starship + mise configs

**Files:**
- Create: `~/workspace/dotfiles/dot_config/starship.toml`
- Create: `~/workspace/dotfiles/dot_config/mise/config.toml`

**Interfaces:**
- Produces: a tuned starship prompt and mise tool versions managed by chezmoi.

- [ ] **Step 1: Write `dot_config/starship.toml`**

```toml
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

[git_branch]
symbol = " "

[kubernetes]
disabled = false
format = 'on [⎈ $context\($namespace\)](dimmed green) '

[directory]
truncation_length = 3
truncate_to_repo = true

[golang]
symbol = " "

[nodejs]
symbol = " "
```

- [ ] **Step 2: Seed `dot_config/mise/config.toml` from the live config**

```bash
mkdir -p ~/workspace/dotfiles/dot_config/mise
cp ~/.config/mise/config.toml ~/workspace/dotfiles/dot_config/mise/config.toml
```

- [ ] **Step 3: Verify starship accepts the config**

Run: `starship config --config dot_config/starship.toml 2>/dev/null || starship print-config --config dot_config/starship.toml >/dev/null && echo OK`
Expected: `OK` (no parse error). If the `--config` flag differs by version, run `STARSHIP_CONFIG=dot_config/starship.toml starship module directory >/dev/null && echo OK`.

- [ ] **Step 4: Verify mise config is valid**

Run: `mise ls --offline 2>/dev/null; cat ~/workspace/dotfiles/dot_config/mise/config.toml | grep node && echo OK`
Expected: `OK` and a `node` line.

- [ ] **Step 5: Commit**

```bash
git add dot_config/starship.toml dot_config/mise/config.toml
git commit -m "feat: add tuned starship config and mise tool versions"
```

---

### Task 8: Bootstrap script + macOS defaults + README

**Files:**
- Create: `~/workspace/dotfiles/run_once_before_10-install-tools.sh.tmpl`
- Create: `~/workspace/dotfiles/dot_macos` (from old `dotfiles/.macos`)
- Modify: `~/workspace/dotfiles/README.md`

**Interfaces:**
- Consumes: rendered `Brewfile` (Task 6).
- Produces: an idempotent pre-apply script that installs Homebrew + `op` if missing and runs `brew bundle`; a kept-but-not-auto-run macOS defaults script; updated bootstrap docs.

- [ ] **Step 1: Write `run_once_before_10-install-tools.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install 1Password CLI early — secret-bearing templates need it
if ! command -v op >/dev/null 2>&1; then
  brew install --cask 1password-cli
fi

# Render the Brewfile from the template (isWork is known at apply time) and install.
# chezmoi processes Brewfile.tmpl into the source-state, so we render it here directly.
RENDERED_BREWFILE="$(mktemp)"
chezmoi execute-template --init --promptBool isWork={{ .isWork }} \
  < "{{ .chezmoi.sourceDir }}/Brewfile.tmpl" > "$RENDERED_BREWFILE"
brew bundle --file="$RENDERED_BREWFILE"
rm -f "$RENDERED_BREWFILE"
```

- [ ] **Step 2: Move the macOS defaults script in (kept, not auto-run)**

```bash
git mv dotfiles/.macos dot_macos
```

> `dot_macos` renders to `~/.macos` and is NOT executed by chezmoi. Run it manually after reviewing: `sh ~/.macos`.

- [ ] **Step 3: Rewrite README.md with the new bootstrap flow**

```markdown
# Dotfiles (chezmoi)

Managed with [chezmoi](https://chezmoi.io). Secrets come from 1Password.

## New machine

1. Install chezmoi and sign into 1Password:
   ```bash
   brew install chezmoi
   brew install --cask 1password-cli && op signin
   ```
2. Initialize (prompts whether this is a work machine):
   ```bash
   chezmoi init --apply git@github.com:jonioliveira/dotfiles.git
   ```

This installs Homebrew (if missing), runs `brew bundle`, and applies all
dotfiles. The macOS defaults script is installed to `~/.macos` but NOT run
automatically — review it, then `sh ~/.macos`.

## Daily use

- Edit a managed file: `chezmoi edit ~/.zshrc`
- Preview changes: `chezmoi diff`
- Apply: `chezmoi apply`
- Pull + apply on another machine: `chezmoi update`
```

- [ ] **Step 4: Verify the bootstrap script renders without template errors**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=false \
  < run_once_before_10-install-tools.sh.tmpl | head -5
```
Expected: valid bash, `#!/usr/bin/env bash` first line, no `<no value>` or template-error text.

- [ ] **Step 5: Commit**

```bash
git add run_once_before_10-install-tools.sh.tmpl dot_macos README.md
git rm -q dotfiles/.macos 2>/dev/null || true
git commit -m "feat: add bootstrap script, keep macos defaults, rewrite README"
```

---

### Task 9: Remove the old Ansible scaffolding

**Files:**
- Delete: `playbook.yml`, `hosts`, `start.sh`, `roles/**`, `dotfiles/.zshrc`, `dotfiles/iterm2_profiles.json`

**Interfaces:**
- Produces: a repo containing only chezmoi-managed source + docs. No Ansible remnants.

- [ ] **Step 1: Confirm every old file has a chezmoi replacement before deleting**

Run:
```bash
ls dot_zshrc.tmpl Brewfile.tmpl dot_gitconfig.tmpl run_once_before_10-install-tools.sh.tmpl && echo "replacements present"
```
Expected: `replacements present`.

- [ ] **Step 2: Remove the Ansible files**

```bash
git rm -r playbook.yml hosts start.sh roles dotfiles/.zshrc dotfiles/iterm2_profiles.json
```

> `dotfiles/.macos` was already moved in Task 8. The now-empty `dotfiles/` dir is removed by the `git rm` of its last contents.

- [ ] **Step 3: Verify the repo tree is chezmoi-only**

Run: `git ls-files | grep -vE '^docs/' | sort`
Expected: only chezmoi source files (`.chezmoi.toml.tmpl`, `.chezmoiignore`, `dot_*`, `private_dot_ssh/config.tmpl`, `Brewfile.tmpl`, `run_once_before_*`, `README.md`). No `roles/`, `playbook.yml`, `start.sh`.

- [ ] **Step 4: Verify chezmoi parses the whole source without error**

Run: `chezmoi verify && echo "source valid"`
Expected: `source valid` (exit 0). `chezmoi verify` fails loudly on any template or attribute error.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove Ansible scaffolding, repo is now chezmoi-only"
```

---

### Task 10: Full dry-run, then apply and verify

**Files:**
- None modified; this task applies the repo to the home directory under review.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: a verified, applied dotfiles state on this (personal) machine.

- [ ] **Step 1: Full dry-run diff against the home directory**

Run: `chezmoi diff`
Expected: review every hunk. The diff shows what `apply` would change in `~`. Confirm `~/.zshrc` changes are only the intended alias/path edits, `~/.gitconfig` gains the delta/pull settings, and no unexpected files are touched. STOP and reconcile if anything surprising appears.

- [ ] **Step 2: Apply with verbose output**

Run: `chezmoi apply --verbose`
Expected: chezmoi reports the files it writes; no errors. (On this personal machine `isWork=false`, so no GitLab/glab artifacts.)

- [ ] **Step 3: Verify the live shell still works**

Run: `zsh -ic 'echo $0; alias dev; which starship mise zoxide' `
Expected: prints the `dev` alias, and resolves starship/mise/zoxide — confirming the rendered `~/.zshrc` sources cleanly.

- [ ] **Step 4: Verify git config resolved correctly**

Run: `git config --get core.pager && git config --get user.email`
Expected: `delta` and `joni@jonioliveira.dev`.

- [ ] **Step 5: Verify Brewfile satisfaction and push the branch**

Run:
```bash
chezmoi execute-template --init --promptBool isWork=false < Brewfile.tmpl > /tmp/Brewfile.final
brew bundle check --file=/tmp/Brewfile.final
git push -u origin chezmoi-migration
```
Expected: `The Brewfile's dependencies are satisfied.` and a pushed branch. Open a PR (or fast-forward `master`) only after manual confirmation that the personal machine is healthy.

---

## Post-Plan: Machine Cleanup (optional, run after merge)

These are independent of the repo and can be done anytime:

- [ ] Remove orphaned `asdf` (mise replaces it): `brew uninstall asdf` (after confirming nothing depends on it).
- [ ] Remove deprecated `hub` (gh replaces it): `brew uninstall hub`.
- [ ] Upgrade outdated formulae: `brew upgrade && brew cleanup && brew autoremove`.

## Notes for the Implementer — values to confirm during execution

These appear as placeholders in the templates and MUST be replaced with real values before the work-machine path is trusted (they do not affect the personal-machine apply in Task 10):

1. `op://Work/git/email` — real 1Password vault/item/field for the work git email (Task 4).
2. `gitlab.company.com` and `~/.ssh/id_ed25519_work` — real work GitLab host + key filename (Task 5).
3. Any work VPN client to add to the work Brewfile block (Task 6).
