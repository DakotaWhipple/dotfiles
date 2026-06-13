#!/usr/bin/env bash
# install.sh — wire the dotfiles into the system. Idempotent; safe to re-run.
set -euo pipefail
DOTS="$HOME/dotfiles"

link() { # link <src> <dst> — backs up anything that isn't already a symlink
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up: $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "linked: $dst -> $src"
}

## config symlinks
link "$DOTS/kitty"                   "$HOME/.config/kitty"
link "$DOTS/aerospace"               "$HOME/.config/aerospace"
link "$DOTS/sketchybar"              "$HOME/.config/sketchybar"
link "$DOTS/borders"                 "$HOME/.config/borders"
link "$DOTS/yazi"                    "$HOME/.config/yazi"
link "$DOTS/zk"                      "$HOME/.config/zk"

chmod +x "$DOTS/bin/"* "$DOTS/sketchybar/sketchybarrc" "$DOTS/sketchybar/plugins/"* "$DOTS/borders/bordersrc"

## shell glue
if ! grep -q 'dotfiles/zsh/rice.zsh' "$HOME/.zshrc" 2>/dev/null; then
  printf '\n# cozy rice (theme, prompt, vi-mode, fzf, yazi)\nsource "$HOME/dotfiles/zsh/rice.zsh"\n' >> "$HOME/.zshrc"
  echo "added rice.zsh to ~/.zshrc"
fi

## CLI upgrades the shell aliases expect
if command -v brew >/dev/null; then
  for t in eza fd bat zoxide fzf starship atuin zk; do
    command -v "$t" >/dev/null || brew install -q "$t"
  done
fi

## note vault — ~/notes (zk; see zk/config.toml and bin/{note,jot,notes})
mkdir -p "$HOME/notes/journal"
if command -v jj >/dev/null && [ ! -d "$HOME/notes/.jj" ]; then
  jj git init "$HOME/notes" >/dev/null && echo "jj repo: ~/notes"
fi

## desktop widgets — Übersicht renders the rice widgets over the wallpaper
if command -v brew >/dev/null && [ ! -d "/Applications/Übersicht.app" ]; then
  brew install -q --cask ubersicht
fi
link "$DOTS/ubersicht" "$HOME/Library/Application Support/Übersicht/widgets/rice"
open -a "Übersicht" 2>/dev/null || true

## wallpapers
for d in "$DOTS/themes"/*/; do
  name="$(basename "$d")"
  [ -f "$DOTS/wallpapers/$name.png" ] || "$DOTS/bin/theme-wallpaper" "$name"
done

## hand the macOS menu bar over to sketchybar
defaults write NSGlobalDomain _HIHideMenuBar -bool true

## hide the stock desktop widgets — sketchybar owns ambient status
defaults write com.apple.WindowManager StandardHideWidgets -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true

## Rectangle conflicts with AeroSpace — retire it
if pgrep -xq Rectangle; then
  osascript -e 'tell application "Rectangle" to quit' || true
  echo "quit Rectangle"
fi
defaults write com.knollsoft.Rectangle launchOnLogin -bool false 2>/dev/null || true

## apply default vibe (before services — they source the active palette)
"$DOTS/bin/theme" set "$(cat "$HOME/.config/theme/current" 2>/dev/null || echo cozy)"

## services — sketchybar and borders are built from source into ~/.local/bin
## (brew refuses to build them while the installed Xcode.app is outdated)
agent() { # agent <label> <program>
  local label="$1" prog="$2" plist="$HOME/Library/LaunchAgents/$1.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$prog</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>EnvironmentVariables</key><dict>
    <key>PATH</key><string>$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
  </dict>
  <key>StandardOutPath</key><string>/tmp/$label.out.log</string>
  <key>StandardErrorPath</key><string>/tmp/$label.err.log</string>
</dict></plist>
EOF
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
  echo "service: $label"
}

agent com.koda.sketchybar "$HOME/.local/bin/sketchybar"
agent com.koda.borders "$HOME/.local/bin/borders"

## bookmarks mirror — snapshot Chrome's bookmarks into the repo on a timer.
## Short-lived job (not a daemon): StartInterval + RunAtLoad, no KeepAlive.
timer() { # timer <label> <interval-seconds> <program...>
  local label="$1" interval="$2" plist="$HOME/Library/LaunchAgents/$1.plist"; shift 2
  local args=""; for a in "$@"; do args+="<string>$a</string>"; done
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array>$args</array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>$interval</integer>
  <key>EnvironmentVariables</key><dict>
    <key>DOTFILES</key><string>$DOTS</string>
    <key>PATH</key><string>$DOTS/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
  </dict>
  <key>StandardOutPath</key><string>/tmp/$label.out.log</string>
  <key>StandardErrorPath</key><string>/tmp/$label.err.log</string>
</dict></plist>
EOF
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
  echo "timer: $label (every ${interval}s)"
}

timer com.koda.bookmarks 1800 /usr/bin/python3 "$DOTS/bin/bookmarks" save

echo
echo "done. open AeroSpace and Homerow once to grant Accessibility permission:"
echo "  open -a AeroSpace && open -a Homerow"
echo
echo "chrome: load the vibe new-tab once via chrome://extensions ->"
echo "  'Developer mode' -> 'Load unpacked' -> $DOTS/chrome"
