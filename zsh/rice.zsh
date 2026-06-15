# rice.zsh — sourced from ~/.zshrc. Theme glue + vim-everywhere shell.

export DOTFILES="$HOME/dotfiles"
export PATH="$DOTFILES/bin:$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"
export ZK_NOTEBOOK_DIR="$HOME/notes"  # note vault — `note`, `jot`, `notes` (bin/)

# vi-mode editing (ESC -> normal mode; starship shows ❮ in normal mode)
bindkey -v
export KEYTIMEOUT=1
# keep the good emacs-isms in insert mode
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^?' backward-delete-char
# clear-screen lives on alt+shift+C: ctrl+l is owned by kitty for pane nav
# (neighboring_window) and never reaches the shell. ^[C = ESC then C; ZLE matches
# the full sequence (both bytes buffered), so KEYTIMEOUT=1 doesn't split it.
bindkey '^[C' clear-screen           # insert mode (viins)
bindkey -M vicmd '^[C' clear-screen  # normal mode
bindkey -r '^l'                      # ctrl+l belongs to kitty; drop zsh's default
bindkey -M vicmd -r '^l'

# fzf: keybindings (ctrl-t files) + vibe colors
command -v fzf >/dev/null && source <(fzf --zsh)
[ -f "$HOME/.config/theme/fzf.sh" ] && source "$HOME/.config/theme/fzf.sh"

# atuin: searchable shell history — takes over ctrl-r (after fzf, so it wins);
# up-arrow stays plain zsh so vi-mode k/j history feels normal
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# everyday commands, upgraded + vibe-colored (LS_COLORS/EZA_COLORS follow the theme)
[ -f "$HOME/.config/theme/lscolors.sh" ] && source "$HOME/.config/theme/lscolors.sh"
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -l --git --time-style=relative'
  alias la='eza --icons --group-directories-first -la --git --time-style=relative'
  alias lt='eza --icons --group-directories-first --tree --level=2 --git-ignore'
fi
command -v bat >/dev/null && alias cat='bat --style=plain --paging=never'

# prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# terminal home — greet fresh kitty shells (not nested shells or scripts)
if [[ -o interactive && -z "${RICE_HOME_SHOWN:-}" && -n "${KITTY_WINDOW_ID:-}" ]]; then
  export RICE_HOME_SHOWN=1
  home
fi

# yazi: `y` opens the file manager and cd's to where you quit
function y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# zoxide last — it wants its chpwd/precmd hook registered after everything else
# (e.g. starship), or its doctor warns. `--cmd cd` makes `cd` learn frecency.
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
