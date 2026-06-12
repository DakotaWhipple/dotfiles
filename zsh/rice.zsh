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

# prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# yazi: `y` opens the file manager and cd's to where you quit
function y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
