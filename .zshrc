# === PATH & Environment ===

# rbenv & nodenv inject shims into PATH — must run BEFORE any custom PATH exports
# below, otherwise our additions get clobbered. They also set up completion hooks.
eval "$(rbenv init -)"
eval "$(nodenv init -)"

# ~/.local/bin holds user-installed binaries (e.g. Claude Code CLI).
# Prepending ensures these take priority over Homebrew/system versions.
export PATH="$HOME/.local/bin:$PATH"


# === History ===

HISTSIZE=10000                         # commands kept in memory for the current session
SAVEHIST=10000                         # commands persisted to ~/.zsh_history on exit

setopt HIST_IGNORE_ALL_DUPS            # drop older duplicates entirely — keeps history clean
setopt SHARE_HISTORY                   # all open terminals see each other's history in real time


# === Shell Behavior ===

setopt AUTO_CD                         # typing a dir name alone cd's into it (e.g. `..` instead of `cd ..`)
setopt CORRECT                         # offers spelling correction for mistyped commands
setopt COMPLETE_IN_WORD                # tab-complete from cursor position, not just end of word
setopt INTERACTIVE_COMMENTS            # allow `# comments` mid-line in the interactive shell

# zsh has "magic functions" that auto-quote pasted URLs etc. — they're slow and
# cause noticeable lag when pasting large blocks (e.g. multi-line scripts).
DISABLE_MAGIC_FUNCTIONS=true


# === Aliases ===

alias cat='bat --paging=never --style=plain'
alias ls='eza --color=always --icons=always --long --git --no-filesize --no-time --no-user --no-permissions --tree --level=1'

# Project shortcuts
alias stockroom='cd ~/RAKSUL/raksul-stockroom'
alias stockroom-web='cd ~/RAKSUL/raksul-stockroom-web'

# Dotfiles managed as a BARE git repo at ~/.dotfiles with $HOME as the work tree.
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dotfiles-lzg='lazygit --git-dir=$HOME/.dotfiles --work-tree=$HOME'


# === Completion System ===

# Loads zsh's completion engine. Must run BEFORE plugins that hook into it (fzf, etc.).
autoload -Uz compinit

# Performance trick: compinit's full security check is slow (~100ms+).
# Skip it with `-C` when the dump file is fresh (<24h old).
# The glob qualifier breakdown:
#   (#q...)  — start a glob qualifier
#   N        — NULL_GLOB: don't error if no match (file doesn't exist)
#   .        — only match plain files
#   mh+24    — modified more than 24 HOURS ago
# So: if a 24h+ old dump exists → run full compinit; else → run fast -C variant.
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit                             # stale dump (or first run) → regenerate safely
else
  compinit -C                          # fresh dump → skip security check, much faster
fi

zstyle ':completion:*' use-cache on                      # cache completions to disk
zstyle ':completion:*' cache-path ~/.zsh/cache           # where the cache lives
zstyle ':completion:*' menu select                       # arrow-key navigable completion menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive matching (typing 'doc' matches 'Documents')


# === Keybindings ===
# After fzf so our bindings override any conflicting ones it sets up.

bindkey '^[[Z' reverse-menu-complete   # Shift+Tab cycles BACKWARD through completion menu


# === Plugins ===
# Order is critical here:
#   1. autosuggestions — hooks into ZLE (Zsh Line Editor) to show grey-text predictions
#   2. zsh-syntax-highlighting — MUST be sourced LAST among ZLE plugins,
#      because it wraps ZLE widgets and anything sourced after won't be highlighted.
# Paths are hardcoded to /opt/homebrew (Apple Silicon) — avoids spawning
# `brew --prefix` subprocess (saves ~30ms on shell startup).

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"        # grey color for the suggestion ghost text
ZSH_AUTOSUGGEST_STRATEGY=(history completion)   # try history first, fall back to completion engine
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20              # skip lookup once command exceeds 20 chars (perf)
# Note: ZSH_AUTOSUGGEST_USE_ASYNC is NO LONGER needed — async is the default in modern versions.

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting (zsh-users) — highlights commands as you type (valid/invalid, strings, etc.).
# MUST be sourced last among ZLE plugins — it wraps ZLE widgets, and anything
# sourced after this point won't get highlighted.
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# === Prompt ===
# Always last. Starship only modifies $PROMPT and doesn't touch ZLE,
# so it's safe to run after the highlighting plugin.

eval "$(starship init zsh)"
