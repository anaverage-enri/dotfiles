## Bootstrapping A Brand New Machine

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
