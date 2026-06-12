# koda's cozy rice

One command switches the **vibe** of the whole desktop — terminal, editor,
bar, borders, prompt, file manager, wallpaper — all from a single palette.

```
theme              # list vibes (● = active)
theme forest       # switch everything to the forest vibe
theme-cycle        # next vibe (also: click the  logo in the bar)
```

| vibe   | palette          | feel                              |
|--------|------------------|-----------------------------------|
| cozy   | Catppuccin Mocha | soft pastels on warm dark grey    |
| forest | Everforest       | mossy greens, warm wood tones     |
| space  | Tokyo Night      | deep-space blues, nebula purples  |
| pink   | Rosé Pine        | muted rose, gold and iris on plum |
| retro  | Gruvbox          | warm amber, olive and rust        |
| techy  | Cyberdream       | neon accents on near-black        |

## How it works

`themes/<vibe>/colors.sh` is the single source of truth. `bin/theme`:

- regenerates `kitty/current-theme.conf` and live-recolors every running
  kitty via its remote-control socket
- writes `~/.config/theme/nvim` (read by LazyVim at startup) and sends
  `:colorscheme` over RPC to every running neovim
  (sockets in `~/.cache/nvim/theme-servers/`)
- reloads sketchybar and restyles JankyBorders in place
- flips the starship palette, rewrites fzf colors and the yazi theme
- renders a wallpaper from the palette (`bin/theme-wallpaper`, ffmpeg
  gradient + vignette) and sets it

Adding a vibe = one new `themes/<name>/colors.sh`. Everything else derives.

## Keybindings (mouse optional)

**Windows — AeroSpace (`alt` is the leader)**

| keys                | action                              |
|---------------------|-------------------------------------|
| `alt+hjkl`          | focus window left/down/up/right     |
| `alt+shift+hjkl`    | move window                         |
| `alt+1..9`          | go to workspace                     |
| `alt+shift+1..9`    | send window to workspace            |
| `alt+tab`           | last workspace                      |
| `alt+enter`         | new kitty window                    |
| `alt+f`             | fullscreen                          |
| `alt+shift+f`       | toggle floating                     |
| `alt+-` / `alt+=`   | shrink / grow window                |
| `alt+/` `alt+,`     | tiles / accordion layout            |
| `alt+shift+;`       | service mode (`esc` reload, `r` reset layout) |

**Terminal — kitty + neovim**

| keys              | action                                        |
|-------------------|-----------------------------------------------|
| `ctrl+hjkl`       | move between kitty splits *and* nvim splits seamlessly |
| `ctrl+alt+hjkl`   | resize splits (both worlds)                   |
| `cmd+d` / `cmd+shift+d` | vertical / horizontal split            |
| `cmd+enter`       | auto split                                     |
| `cmd+t`           | new tab (same cwd)                             |
| `cmd+shift+z`     | zoom split (stack layout)                      |

**Shell** — vi-mode (`esc` for normal mode, prompt shows `❮`), `ctrl+r`
fzf history, `ctrl+t` fzf files, `y` opens yazi and cd's where you quit.

**Anywhere** — Homerow: hit its hotkey and type a label to click anything
keyboard-only.

## Install on a new machine

```sh
brew install kitty neovim starship yazi fzf jq zoxide ffmpeg \
  font-jetbrains-mono-nerd-font
brew trust nikitabobko/tap && brew install --cask nikitabobko/tap/aerospace homerow
# sketchybar + borders: brew install if Xcode is current, else build from
# source (FelixKratz/SketchyBar, FelixKratz/JankyBorders) into ~/.local/bin
./install.sh
```

`install.sh` is idempotent: symlinks configs into `~/.config` (backing up
originals), adds `zsh/rice.zsh` to `.zshrc`, renders wallpapers, installs
launchd agents for sketchybar/borders, hides the macOS menu bar, and
applies the current vibe.
