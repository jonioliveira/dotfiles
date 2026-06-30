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
