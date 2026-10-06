# dotfiles

My macOS dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## What's in here

| Tool | Files |
|---|---|
| zsh | `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.config/zsh/` |
| Neovim | `~/.config/nvim/` (lazy.nvim, Nord theme) |
| Ghostty | `~/.config/ghostty/` |
| herdr | `~/.config/herdr/` |
| Starship | `~/.config/starship/` |
| Yazi | `~/.config/yazi/` |
| mise | `~/.config/mise/config.toml` (global tool versions) |
| opencode | `~/.config/opencode/` (config, AGENTS.md, skills) |
| git, terraform | `~/.gitconfig`, `~/.terraformrc` |
| Homebrew | `Brewfile` (installed by a chezmoi script, not copied to `$HOME`) |

## New machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply carlosj934
```

This will:

1. Install Apple's command line tools and Homebrew if they're missing.
2. Run `brew bundle` with the `Brewfile`.
3. Copy every config file into place.
4. Run `mise install` for the global tool versions.

Secrets are never stored here. `~/.zshenv` loads `~/.env` if it exists, so keep API keys there.

## Day to day

```sh
chezmoi edit --apply ~/.zshrc        # edit a managed file and apply it
chezmoi re-add                       # pull in changes made directly to managed files
chezmoi diff                         # see what would change
chezmoi cd                           # jump to this repo, then git add/commit/push
chezmoi update                       # on another machine: pull and apply
```

The Brewfile and mise scripts re-run automatically whenever the `Brewfile` or `config.toml` changes.
