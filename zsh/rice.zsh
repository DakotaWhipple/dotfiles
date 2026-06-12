# rice.zsh — sourced from ~/.zshrc. Theme glue + vim-everywhere shell.

export DOTFILES="$HOME/dotfiles"
export PATH="$DOTFILES/bin:$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"

# vi-mode editing (ESC -> normal mode; starship shows ❮ in normal mode)
bindkey -v
export KEYTIMEOUT=1
# keep the good emacs-isms in insert mode
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^?' backward-delete-char

# fzf: keybindings (ctrl-r history, ctrl-t files) + vibe colors
command -v fzf >/dev/null && source <(fzf --zsh)
[ -f "$HOME/.config/theme/fzf.sh" ] && source "$HOME/.config/theme/fzf.sh"

# everyday commands, upgraded + vibe-colored (LS_COLORS/EZA_COLORS follow the theme)
[ -f "$HOME/.config/theme/lscolors.sh" ] && source "$HOME/.config/theme/lscolors.sh"
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -l --git --time-style=relative'
  alias la='eza --icons --group-directories-first -la --git --time-style=relative'
  alias lt='eza --icons --group-directories-first --tree --level=2 --git-ignore'
fi
command -v bat >/dev/null && alias cat='bat --style=plain --paging=never'
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"  # cd learns frecency

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
