# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a personal **dotfiles repository** managed as a bare git repo at `~/.dotfiles` with `$HOME` as the working tree. It tracks shell configuration, tool settings, and machine bootstrap instructions.

## Working With Dotfiles

All git operations on dotfiles use the `dotfiles` alias instead of `git`:

```bash
dotfiles status
dotfiles add ~/.zshrc
dotfiles commit -m "..."
dotfiles push
```

For a visual TUI, use `dotfiles-lzg` (lazygit with the bare repo flags).

The remote is `git@github.com:anaverage-enri/dotfiles.git`.

Untracked files in `$HOME` are hidden by default (`status.showUntrackedFiles = no`) — this is intentional.

## Bootstrapping a New Machine

See `~/README.md` for the full bootstrap procedure. The key steps are:
1. Clone bare repo to `~/.dotfiles`
2. Define the `dotfiles` alias
3. Run `dotfiles checkout` (with backup handling for conflicting files)
4. Set `dotfiles config --local status.showUntrackedFiles no`
5. In Ghostty config, add `config-file = ~/.config/ghostty/config.ghostty`

## Shell Environment

- **Shell**: zsh with Starship prompt
- **Node**: managed via `nodenv`
- **Ruby**: managed via `rbenv`
- **User binaries**: `~/.local/bin` (takes priority over Homebrew)
Key aliases defined in `.zshrc`:
- `cat` → `bat` (syntax highlighting)
- `ls` → `eza` (tree view, icons, git status)
- `lzg` → `lazygit`

## Git Config Highlights (`.gitconfig`)

- Default branch: `main`
- `push.autoSetupRemote = true` — no need to set upstream manually
- `fetch.prune = true` — auto-removes deleted remote branches
- `merge.conflictstyle = zdiff3`
- Alias `pf` = `push --force-with-lease`

