# Course: hacking — how THIS machine works, jj, plugin anatomy, and
# the road to contributing upstream.
COURSE_TITLE="Hack the Dotfiles (and Beyond)"
COURSE_DESC="The endgame: stop being a user of this setup and become
its author. The repo map, jj, what an nvim plugin actually is, and
how people start contributing to the tools they use."

LESSONS=(
  "tour:The repo, mapped"
  "jj:Version control with jj"
  "plugins:Anatomy of an nvim plugin"
  "contribute:The road to open source"
)

lesson_tour() {
  brief "~/dotfiles, the load-bearing walls:

  bin/            your commands (note, jot, theme, dojo...)
  zsh/rice.zsh    everything shell — PATH, aliases, vi-mode
  kitty/ aerospace/ starship/   one config file each
  themes/ + bin/theme-*         the vibe system: 'theme set cozy'
        seeds a palette (OKLCH math in theme-palette), then
        writes kitty colors, nvim colorscheme, borders,
        sketchybar, wallpaper — one command, whole desktop
  zk/             notes config (vault is ~/notes, separate)
  dojo/           this thing — courses are plain bash files
  install.sh      symlinks configs into ~/.config

nvim is the one split brain: LazyVim lives in ~/.config/nvim,
the generated rice colorschemes in ~/dotfiles/nvim/rice."

  guided "Run: lt ~/dotfiles   (tree view). Then read one tool
end to end: bat ~/dotfiles/bin/theme — see it write the files
other apps watch."

  quiz "Change the whole desktop vibe?" "theme set" ""
  quiz "Which script computes palettes from a seed?" "theme-palette" ""
  quiz "Where do nvim plugin SPECS live?" "lua/plugins|~/.config/nvim/lua/plugins" ""
}

lesson_jj() {
  brief "This repo uses jj (colocated with git). The mental model:
no staging area — the working copy IS a commit, always. You
describe it, start a new one, repeat.

  jj st            what changed?
  jj diff          show the changes
  jj describe -m \"msg\"    name the current change
  jj new           seal it, start the next change
  jj log           the graph
  jj undo          undo the last jj operation (any of them!)
  jj squash        fold this change into its parent"

  shell_task "In the sandbox: make a project and watch jj see it.
  mkdir proj && cd proj
  jj git init
  echo hi > readme.md
  jj st         (it already tracks the file — no add!)
  jj describe -m 'start readme'" \
    '[ -d proj/.jj ] && [ -f proj/readme.md ] && (cd proj && jj log 2>/dev/null | grep -qi "start readme")' \
    "jj git init inside proj, then describe -m"

  quiz "See what changed?" "jj st|jj status" ""
  quiz "Made a mess? Undo the last jj operation?" "jj undo" ""
  quiz "Seal this change and start the next?" "jj new" ""
}

lesson_plugins() {
  brief "An nvim plugin is just lua files in a folder. A SPEC tells
lazy.nvim what to fetch and when to load it:

  {
    \"zk-org/zk-nvim\",            -- github owner/repo
    ft = \"markdown\",             -- lazy-load: only for markdown
    keys = { ... },              -- ...or when these keys are hit
    opts = { picker = ... },     -- passed to the plugin's setup()
    config = function() ... end, -- or full custom setup
  }

Your specs: ~/.config/nvim/lua/plugins/*.lua (notes.lua is a
great read). The DOWNLOADED SOURCE of every plugin sits in
~/.local/share/nvim/lazy/<name> — real code you can read."

  guided "In nvim: :Lazy — the manager UI. See load times, what is
lazy vs loaded. q to close. Then space ff in
~/.local/share/nvim/lazy/zk-nvim and skim a lua file — plugin
source is shockingly readable."

  quiz "Open the plugin manager UI?" ":lazy|lazy" ""
  quiz "Spec field that lazy-loads by filetype?" "ft" ""
  quiz "Where is downloaded plugin source?" "~/.local/share/nvim/lazy|.local/share/nvim/lazy" ""
}

lesson_contribute() {
  brief "How people actually get into open source (in order):

  1. READ the source of tools you use. You already can — plugins
     are small lua, your bin/ tools are small bash.
  2. Scratch your own itch in YOUR config first. A keymap, a
     tiny function. The dojo itself is moddable: add a quiz to
     any drills() and it shows up in the arcade tonight.
  3. First upstream PR: docs. A typo, a misleading README line,
     a missing example. Maintainers love these.
  4. Then: reproduce a bug from the issue tracker, comment your
     findings. Then fix one labeled 'good first issue'.

  gh repo fork owner/repo --clone    fork + clone in one move
  small branch, small diff, kind description. That is it.

Good first targets from YOUR stack: zk-nvim, harpoon,
smart-splits.nvim, yazi docs — all communities used to newcomers."

  guided "Pick the plugin you are most curious about and run:
  gh repo view zk-org/zk-nvim --web    (or harpoon, etc.)
Read 3 open issues. Just read. Notice how many are answerable
by someone who simply uses the thing daily — that is you."

  quiz "Classic first contribution?" "docs|typo|documentation|readme" ""
  quiz "Fork and clone in one gh command?" "gh repo fork|gh repo fork --clone" ""

  brief "Final note. You now know: an editor language (vim), a
window grammar (hjkl everywhere), a capture habit (alt+n),
scripting, and where every wire in this machine runs.
Add a course to the dojo (see dojo/README.md) — rust, spanish,
whatever is next. The infrastructure does not care what it
teaches. Replay the gym. Beat your times. ⛩"
}

drills() {
  add_quiz "Switch the desktop vibe?" "theme set"
  add_quiz "jj: what changed?" "jj st|jj status"
  add_quiz "jj: name the current change?" "jj describe|jj describe -m"
  add_quiz "jj: undo anything?" "jj undo"
  add_quiz "jj: start the next change?" "jj new"
  add_quiz "nvim plugin manager UI?" ":lazy"
  add_quiz "Spec field for lazy-loading on keys?" "keys"
  add_quiz "Where does downloaded plugin source live?" "~/.local/share/nvim/lazy|.local/share/nvim/lazy"
  add_quiz "gh: fork + clone?" "gh repo fork|gh repo fork --clone"
  add_quiz "Best first PR type?" "docs|typo|documentation"
}
