# Dotfiles

Personal dotfiles managed as a bare git repo with `$HOME` as the working tree.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Bootstrapping A New Machine](#bootstrapping-a-new-machine)
- [Notes](#notes)

---

## Repository Structure

```
$HOME/
├── .config/
│   ├── ghostty/
│   │   └── config.ghostty   # Ghostty terminal emulator config
│   ├── nvim/
│   │   └── init.lua         # Neovim config
│   └── starship.toml        # Starship prompt config
├── .gitconfig               # Git global config (aliases, defaults)
├── .zshrc                   # Zsh shell config, aliases, env setup
├── AGENTS.md                # Agent instructions for AI tools
├── CLAUDE.md                # Claude Code project instructions
└── README.md                # This file
```

---

## Bootstrapping A New Machine

A fresh machine already has `~/.zshrc` (possibly empty, possibly with some boilerplate), `~/.zprofile`, maybe `~/.gitconfig`.
If you `git checkout` over the top, Git refuses with "the following untracked working tree files would be overwritten."
The canonical fix is to clone into a scratch directory, move the metadata into place, then use `checkout` with a backup step for conflicting files:

```bash
# On the new Mac, after installing Homebrew + git (see bootstrap script)
git clone --bare git@github.com:anaverage-enri/dotfiles.git $HOME/.dotfiles
```

```bash
# Define the alias in the current shell
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

```bash
# Try to check out into $HOME
mkdir -p $HOME/.dotfiles-backup
if ! dotfiles checkout 2>/dev/null; then
  echo "Backing up pre-existing dotfiles..."
  dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | \
    xargs -I{} sh -c 'mkdir -p "$HOME/.dotfiles-backup/$(dirname {})" && mv "$HOME/{}" "$HOME/.dotfiles-backup/{}"'
  dotfiles checkout
fi
```

```bash
# Make sure Git bare repo doesn't track all files from $HOME
dotfiles config --local status.showUntrackedFiles no
```

That `awk`/`xargs` dance parses Git's error output to find exactly the conflicting files, moves them to `~/.dotfiles-backup/` preserving subdirectory structure, and retries the checkout.
It's ugly but it's recommended by Atlassian and it works.

---

## Notes

Inside Ghostty default configuration file, make sure to add
```bash
config-file = ~/.config/ghostty/config.ghostty
```
To point Ghostty to use the managed configuration file instead.
