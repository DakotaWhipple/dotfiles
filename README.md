# koda's cozy rice

One command switches the **vibe** of the whole desktop — terminal, editor,
bar, borders, prompt, file manager, wallpaper — all from a single palette.

```
theme              # list vibes (● = active)
theme forest       # switch everything to the forest vibe
theme-cycle        # next vibe (also: click the  logo in the bar)
```

| vibe   | feel                              |
|--------|-----------------------------------|
| cozy   | Catppuccin Mocha, soft pastels on warm dark grey (pinned) |
| forest | mossy greens, warm wood light     |
| space  | deep-night blues, indigo glow     |
| pink   | dusty rose on midnight plum       |
| retro  | amber CRT warmth, faded paper     |
| techy  | electric blue on near-black       |

## How it works

Palettes are **generated, not curated**. `themes/<vibe>/seed.sh` states a few
hues and mood multipliers; `bin/theme-palette` derives the full palette in
OKLCH — uniform lightness/chroma across the ANSI row, foreground pinned to a
WCAG contrast target, focus borders mixed toward the background (~3:1, a glow
instead of a razor edge), IntelliJ-flavored syntax roles, wallpaper gradient
stops — and writes `themes/<vibe>/colors.sh`, a `rice-<vibe>` neovim
colorscheme, and the starship palettes. cozy pins stock Catppuccin Mocha and
only derives the extra roles.

`themes/<vibe>/colors.sh` is then the runtime source of truth. `bin/theme`:

- regenerates `kitty/current-theme.conf` and live-recolors every running
  kitty via its remote-control socket
- writes `~/.config/theme/nvim` (read by LazyVim at startup) and sends
  `:colorscheme` over RPC to every running neovim
  (sockets in `~/.cache/nvim/theme-servers/`)
- reloads sketchybar and restyles JankyBorders in place
- flips the starship palette, rewrites fzf colors and the yazi theme
- regenerates truecolor `LS_COLORS`/`EZA_COLORS` so `ls`/`ll`/`la` (eza),
  `cat` (bat) and fd follow the vibe
- rewrites `chrome/theme.css` so the Rice Tab new-tab page follows too
- renders a wallpaper from the palette (`bin/theme-wallpaper`, ffmpeg
  gradient + vignette) and sets it

Adding a vibe = one new `themes/<name>/seed.sh` + `theme-palette <name>`.
Everything else derives.

## Chrome

`chrome/` is an unpacked extension (load once: `chrome://extensions` →
Developer mode → Load unpacked → `~/dotfiles/chrome`). It replaces the new
tab with a clock + your bookmarks-bar folders, colored by the active vibe.

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
| `ctrl+;`          | **manage mode** (zellij-style, home row)       |

**Manage mode** (`ctrl+;`, then): `h/l` prev/next tab · `j/k` cycle windows ·
`H/L` reorder tabs · `1-5` jump to tab · `n` new tab · `s/v` splits ·
`z` zoom · `x` close window · `,` rename tab · `r` resize submode (hjkl) ·
`esc`/`enter` leave.

**Shell** — vi-mode (`esc` for normal mode, prompt shows `❮`), `ctrl+r`
fzf history, `ctrl+t` fzf files, `y` opens yazi and cd's where you quit,
`cd` is zoxide (frecency jumps), `ls/ll/la/lt` are eza with vibe colors,
`cat` is bat. The prompt shows the jj change id + bookmark in jj repos.

**Anywhere** — Homerow: hit its hotkey and type a label to click anything
keyboard-only.

## Install on a new machine

```sh
brew install kitty neovim starship yazi fzf jq zoxide ffmpeg \
  eza fd bat font-jetbrains-mono-nerd-font
brew trust nikitabobko/tap && brew install --cask nikitabobko/tap/aerospace homerow
# sketchybar + borders: brew install if Xcode is current, else build from
# source (FelixKratz/SketchyBar, FelixKratz/JankyBorders) into ~/.local/bin
./install.sh
```

`install.sh` is idempotent: symlinks configs into `~/.config` (backing up
originals), adds `zsh/rice.zsh` to `.zshrc`, renders wallpapers, installs
launchd agents for sketchybar/borders, hides the macOS menu bar, and
applies the current vibe.
