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
| pink   | hot pink on deep raspberry plum   |
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
- refreshes the Übersicht desktop widgets
- renders a wallpaper from the palette (`bin/theme-wallpaper`, ffmpeg
  gradient + vignette) and sets it

Adding a vibe = one new `themes/<name>/seed.sh` + `theme-palette <name>`.
Everything else derives.

## The three homes

Chrome new tab, fresh terminal, and the desktop share one visual language:
big thin clock, vibe dot + name, palette strip, glassy cards over the
wallpaper gradient.

**Chrome** — `chrome/` is an unpacked extension (load once:
`chrome://extensions` → Developer mode → Load unpacked → `~/dotfiles/chrome`).
The new tab is a dashboard: clock, filter-as-you-type search (`/` to focus —
enter opens the first hit, or web-searches), daily pill row, a **rediscover**
row (random picks from the catalog), and bookmark folder cards. Saving is
Chrome's own ★ star — new saves surface in the **recent** card, where a
hover control files them into folders (same for the **inbox** folder).
The page only *reads* `chrome.bookmarks` — Chrome is the source of truth, so
deletes and edits stick. `bin/bookmarks` mirrors Chrome ↔ the repo:

```
bookmarks save      snapshot Chrome's bookmarks -> chrome/bookmarks.json
bookmarks restore   rebuild Chrome's bookmarks from the mirror (quit Chrome first)
```

`chrome/bookmarks.json` is a clean folder/name/url tree (no guids or
timestamps), committed for version control and portability. A launchd timer
(`com.koda.bookmarks`, every 30 min) keeps the mirror trailing Chrome; commit
it whenever. On a fresh machine, `bookmarks restore` rebuilds the profile.

**Terminal** — `bin/home` greets each fresh kitty shell: block-digit clock,
date, vibe + palette strip, jj status. Run `home` anytime.

**Desktop** — Übersicht widgets in `ubersicht/` (symlinked by install.sh):
`rice-clock` bottom-left, `rice-sys` (load/mem/disk/uptime) bottom-right,
`rice-cal` (month, today highlighted) top-right. All read the active
`colors.sh` and re-theme on `theme set`.

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
atuin history search, `ctrl+t` fzf files, `y` opens yazi and cd's where you quit,
`cd` is zoxide (frecency jumps), `ls/ll/la/lt` are eza with vibe colors,
`cat` is bat. The prompt shows the jj change id + bookmark in jj repos.

**Anywhere** — Homerow: hit its hotkey and type a label to click anything
keyboard-only.

## Learn it: the dojo

```
dojo
```

An interactive trainer for everything above — terminal, notes, vim (timed
drills with personal bests), kitty, aerospace, zsh, bash scripting, and the
road to contributing upstream. Lessons verify for real (it watches your
actual kitty splits and aerospace workspaces), every lesson keeps stars and
best times, each course has a rapid-fire arcade with high scores, and
`dojo gym` serves random timed vim drills. See `dojo/README.md` — adding a
new course (rust, spanish, anything) is one bash file.

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
originals), adds `zsh/rice.zsh` to `.zshrc`, installs Übersicht + links the
rice widgets, renders wallpapers, installs launchd agents for
sketchybar/borders, hides the macOS menu bar, and applies the current vibe.
