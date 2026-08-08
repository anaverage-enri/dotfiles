# --- PATH & Environment ---

# rbenv & nodenv inject shims into PATH — must run BEFORE any custom PATH exports
# below, otherwise our additions get clobbered. They also set up completion hooks.
eval "$(rbenv init -)"
eval "$(nodenv init -)"

# ~/.local/bin holds user-installed binaries (e.g. Claude Code CLI).
# Prepending ensures these take priority over Homebrew/system versions.
export PATH="$HOME/.local/bin:$PATH"


# --- History ---

HISTSIZE=10000                         # commands kept in memory for the current session
SAVEHIST=10000                         # commands persisted to ~/.zsh_history on exit

setopt HIST_IGNORE_ALL_DUPS            # drop older duplicates entirely — keeps history clean
setopt SHARE_HISTORY                   # all open terminals see each other's history in real time


# --- Shell Behavior ---

setopt AUTO_CD                         # typing a dir name alone cd's into it (e.g. `..` instead of `cd ..`)
setopt CORRECT                         # offers spelling correction for mistyped commands
setopt COMPLETE_IN_WORD                # tab-complete from cursor position, not just end of word
setopt INTERACTIVE_COMMENTS            # allow `# comments` mid-line in the interactive shell

# zsh has "magic functions" that auto-quote pasted URLs etc. — they're slow and
# cause noticeable lag when pasting large blocks (e.g. multi-line scripts).
DISABLE_MAGIC_FUNCTIONS=true


# --- Aliases ---

alias cat='bat --paging=never --style=plain'
alias ls='eza --color=always --icons=always --long --git --no-filesize --no-time --no-user --no-permissions --tree --level=1'
alias lzg='lazygit'

# Project shortcuts
alias stockroom='cd ~/RAKSUL/raksul-stockroom'
alias stockroom-web='cd ~/RAKSUL/raksul-stockroom-web'

# Dotfiles managed as a BARE git repo at ~/.dotfiles with $HOME as the work tree.
export DOTFILES_DIR="$HOME/.dotfiles"

alias dotfiles='/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME'
alias dotfiles-lzg='lazygit --git-dir=$DOTFILES_DIR --work-tree=$HOME'
alias dotfiles-claude='GIT_DIR=$DOTFILES_DIR GIT_WORK_TREE=$HOME claude'

# Git aliases for quality of life
alias git-co='git checkout $(git branch | fzf --preview-window=hidden)'


# --- Completion System ---

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


# --- bat ---
export BAT_THEME=Coldark-Dark


# --- fzf ---
# Placement note: must come AFTER compinit (it hooks into completion) and
# BEFORE custom keybindings (so ours win if there's a conflict).

export COLORTERM=truecolor                              # signals 24-bit color support for previews

# Sets up Ctrl-T (file picker), Ctrl-R (history), Alt-C (cd picker), and tab completion.
source <(fzf --zsh)

# Default search commands — fd is faster than find and respects .gitignore.
# --strip-cwd-prefix removes the leading `./` from results.
export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude .git --strip-cwd-prefix"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git --strip-cwd-prefix"

# Make path completion (**<TAB>) use fd as well
_fzf_compgen_path() {
  fd --hidden --follow --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude .git . "$1"
}

# Shared preview logic — referenced by multiple FZF_*_OPTS below.
# Branches:
#   - directories  → show 2-level tree (eza)
#   - binary files → show metadata only (avoids garbage)
#   - text files   → show first 100 lines with syntax highlighting (bat)
export FZF_PREVIEW_COMMAND='
if [ -d {} ]; then
  eza --tree --level=2 --color=always --icons {};
elif file --mime {} | grep -q binary; then
  file {};
else
  bat -n --color=always --line-range :100 {};
fi
'

# Default opts. NOTE: fzf parses this as a command-line string, so:
#   - outer "..." so $FZF_PREVIEW_COMMAND gets expanded here
#   - inner '...' around any value with spaces (color, bind, preview)
export FZF_DEFAULT_OPTS="
  --layout=reverse
  --border=rounded
  --margin=1.5%
  --height=80%
  --input-border=rounded
  --preview-border=rounded
  --preview-window=right,60%
  --ansi
  --color='border:#5b595c,input-border:#caa6ff,preview-border:#78dce8,list-border:#ff6188'
  --bind='ctrl-/:change-preview-window(hidden|)'
  --preview='$FZF_PREVIEW_COMMAND'
"

# Per-binding overrides — these merge with FZF_DEFAULT_OPTS.
export FZF_CTRL_T_OPTS="--preview '$FZF_PREVIEW_COMMAND'"               # Ctrl-T: file picker preview

# Ctrl-R: history entries aren't paths, so the inherited bat preview is useless, use custom `echo` for preview instead
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=up,3,wrap
  --bind='ctrl-/:toggle-preview'
"

export FZF_COMPLETION_PATH_OPTS="--preview '$FZF_PREVIEW_COMMAND'"      # **<TAB>: file completion
export FZF_COMPLETION_DIR_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"


# --- zoxide ---
eval "$(zoxide init zsh)"


# --- Keybindings ---
# After fzf so our bindings override any conflicting ones it sets up.

bindkey '^[[Z' reverse-menu-complete   # Shift+Tab cycles BACKWARD through completion menu


# --- Plugins ---
# Order is critical here:
#   1. autosuggestions — hooks into ZLE (Zsh Line Editor) to show grey-text predictions
#   2. zsh-syntax-highlighting — MUST be sourced LAST among ZLE plugins,
#      because it wraps ZLE widgets and anything sourced after won't be highlighted.
# Paths are hardcoded to /opt/homebrew (Apple Silicon) — avoids spawning
# `brew --prefix` subprocess (saves ~30ms on shell startup).

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"        # grey color for the suggestion ghost text
ZSH_AUTOSUGGEST_STRATEGY=(history completion)   # try history first, fall back to completion engine
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20              # skip lookup once command exceeds 20 chars (perf)

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting (zsh-users) — highlights commands as you type (valid/invalid, strings, etc.).
# MUST be sourced last among ZLE plugins — it wraps ZLE widgets, and anything
# sourced after this point won't get highlighted.
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# --- Prompt ---
# Always last. Starship only modifies $PROMPT and doesn't touch ZLE,
# so it's safe to run after the highlighting plugin.

eval "$(starship init zsh)"
