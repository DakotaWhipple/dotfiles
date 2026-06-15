# Course: LazyVim — your distro, its structure, and the spec system.
COURSE_TITLE="LazyVim Mastery"
COURSE_DESC="Your nvim IS LazyVim: a curated lazy.nvim spec you extend
and override. Learn the file layout, the plugin spec, how to add and
override plugins cleanly, and the extras system — so the distro is
yours, not a black box."

LESSONS=(
  "layout:The config layout"
  "spec:Anatomy of a plugin spec"
  "add:Adding a plugin"
  "override:Overriding LazyVim defaults"
  "extras:Extras & the lazyvim.json"
  "keymaps:Keymaps the LazyVim way"
  "mechanics:lazy.nvim mechanics & :Lazy"
)

# ------------------------------------------------------------------ layout
lesson_layout() {
  brief "LazyVim lives in ~/.config/nvim with a fixed shape:

  init.lua                     bootstraps lazy + the LazyVim spec
  lua/config/lazy.lua          where lazy.nvim is set up + imports
  lua/config/options.lua       your vim.opt overrides (loaded early)
  lua/config/keymaps.lua       your extra keymaps
  lua/config/autocmds.lua      your extra autocmds
  lua/plugins/*.lua            ONE FILE PER concern; each returns a
                               spec (or list of specs). Auto-imported.
  lazyvim.json                 which Extras are enabled
  lazy-lock.json               pinned commit of every plugin (commit it)

The three config/*.lua files are merged with LazyVim's own defaults —
you don't replace, you ADD. Anything in lua/plugins is picked up
automatically; no manual 'require' needed."

  quiz "Folder where you drop new plugin spec files?" "lua/plugins|plugins" ""
  quiz "File for your own option overrides?" "options.lua|lua/config/options.lua" ""
  quiz "File listing which Extras are on?" "lazyvim.json" ""
  quiz "File pinning each plugin's commit (commit it!)?" "lazy-lock.json|lockfile" ""
  quiz "Do files in lua/plugins need a manual require?" "no|false" \
    "LazyVim auto-imports every file in lua/plugins"
}

# -------------------------------------------------------------------- spec
lesson_spec() {
  brief "A plugin SPEC is a Lua table. The first element is the repo;
the rest configures it:

  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',        -- lazy trigger
    opts = { signs = true },   -- becomes require(mod).setup(opts)
    keys = { { ']t', desc = 'Next todo' } },
    dependencies = { 'nvim-lua/plenary.nvim' },
    enabled = true,            -- false to disable entirely
  }

A file in lua/plugins can return ONE spec, or a LIST of specs:
  return { { 'repo/a' }, { 'repo/b' } }

The magic of LazyVim: specs with the SAME repo name are MERGED across
files. That's how you tweak a plugin LazyVim already defined — you add
a spec with the same name and only your opts/keys."

  quiz "First positional element of a spec?" "the repo|repo|owner/repo" "'owner/name'"
  quiz "Field that becomes setup(opts)?" "opts" ""
  quiz "Disable a plugin entirely?" "enabled=false|enabled = false|enabled" ""
  quiz "Can one file return a LIST of specs?" "yes|true" "return { {specA}, {specB} }"
  quiz "How does LazyVim let you tweak a built-in plugin?" "same repo name merges|merge by name|same name" \
    "add a spec with the same repo; opts/keys merge into LazyVim's"

  shell_task \
"Create myplugin.lua that returns a single spec table for the repo
'folke/zen-mode.nvim' with opts = { window = { width = 90 } }. The
check dofile()s it and verifies spec[1] and spec.opts.window.width." \
    'printf "local s = dofile(\"./myplugin.lua\")\nprint(s[1], s.opts.window.width)\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -q "folke/zen-mode.nvim.*90"' \
    "return { 'folke/zen-mode.nvim', opts = { window = { width = 90 } } }"
}

# --------------------------------------------------------------------- add
lesson_add() {
  brief "Adding a brand-new plugin is one tiny file. Say you want
nvim-colorizer:

  -- lua/plugins/colorizer.lua
  return {
    'catgoose/nvim-colorizer.lua',
    event = 'BufReadPre',                -- lazy: load on opening a file
    opts = {},
  }

Save, restart (or :Lazy sync), done. lazy.nvim clones it on next start.
Tips:
  - name the file after the plugin so you can find it later
  - prefer a lazy trigger (event/ft/cmd/keys) over loading eagerly
  - opts = {} still calls setup({}) — many plugins NEED setup called
  - :Lazy reload <name> hot-reloads while you iterate"

  quiz "What triggers the clone/install of a newly-added plugin?" "restart or :Lazy sync|:Lazy sync|lazy sync" ""
  quiz "Common lazy trigger for 'when I open a file'?" "BufReadPre|event|BufRead" ""
  quiz "Even with no options, why write opts = {}?" "it calls setup|setup({})|to call setup" \
    "many plugins do nothing until setup() runs once"

  shell_task \
"Create lua/plugins/colorizer.lua returning a spec for
'catgoose/nvim-colorizer.lua' with event = 'BufReadPre' and opts = {}.
Check dofile()s it and verifies the repo + event." \
    'printf "local s = dofile(\"./lua/plugins/colorizer.lua\")\nprint(s[1], s.event)\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -q "catgoose/nvim-colorizer.lua.*BufReadPre"' \
    "mkdir -p lua/plugins; return { 'catgoose/nvim-colorizer.lua', event = 'BufReadPre', opts = {} }"
}

# ---------------------------------------------------------------- override
lesson_override() {
  brief "The real power: bending LazyVim's OWN plugins. Add a spec with
the same repo name; LazyVim merges it. Three override styles:

  1) opts as a TABLE — deep-merged into LazyVim's opts:
     { 'nvim-treesitter/nvim-treesitter', opts = { indent = { enable = true } } }

  2) opts as a FUNCTION — when you must APPEND to a list LazyVim built:
     { 'nvim-treesitter/nvim-treesitter', opts = function(_, opts)
         vim.list_extend(opts.ensure_installed, { 'rust', 'go' })
       end }
     (table merge can't append to a list — use the function form.)

  3) keys / enabled / event — override triggers or turn it off:
     { 'folke/flash.nvim', enabled = false }

The function form is the one people miss: opts(_, opts) hands you the
already-merged table to mutate. Return a new table to REPLACE instead."

  quiz "Override that DEEP-MERGES into existing options?" "opts table|opts as a table|table" ""
  quiz "To APPEND to a list option LazyVim built, opts must be a?" "function|opts function" \
    "opts = function(_, opts) vim.list_extend(opts.x, {...}) end"
  quiz "Helper to append items to an existing list option?" "vim.list_extend|list_extend" ""
  quiz "Turn a LazyVim default plugin off?" "enabled=false|enabled = false" ""

  shell_task \
"Write override.lua: a spec for 'nvim-treesitter/nvim-treesitter' whose
opts is a FUNCTION(_, opts) that does
vim.list_extend(opts.ensure_installed, { 'go' }). The check seeds
opts={ensure_installed={'lua'}}, runs your function, prints the list." \
    'printf "local s = dofile(\"./override.lua\")\nlocal o = { ensure_installed = { \"lua\" } }\ns.opts(nil, o)\nprint(table.concat(o.ensure_installed, \",\"))\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx "lua,go"' \
    "return { 'nvim-treesitter/nvim-treesitter', opts = function(_, opts) vim.list_extend(opts.ensure_installed, {'go'}) end }"
}

# ------------------------------------------------------------------ extras
lesson_extras() {
  brief "EXTRAS are LazyVim's pre-built, curated plugin bundles —
language support, DAP, test runners, extra editor tools. Don't hand-wire
a Rust setup; enable the extra.

  :LazyExtras            the UI — x to toggle one on/off
  lang.rust               raLSP + crates.nvim + formatting, wired
  lang.go / lang.python / lang.typescript ...
  coding.* editor.* dap.* test.* util.*

Enabling one writes its name into lazyvim.json (the 'extras' list) and
pulls in its specs on next start. The lua/plugins override rules still
apply — you can tweak any plugin an extra brought in by adding a spec
with the same name. COMMIT lazyvim.json so the set is reproducible."

  quiz "Command to browse/toggle Extras?" "LazyExtras|:LazyExtras" ""
  quiz "File that records enabled extras?" "lazyvim.json" ""
  quiz "Extra family for language support (LSP+fmt+tools)?" "lang|lang.*" \
    "lang.rust, lang.go, lang.python — batteries included per language"
  quiz "Can you still override a plugin an extra installed?" "yes|true" \
    "same-name spec in lua/plugins merges, extra or not"

  guided "In real nvim: run :LazyExtras. Browse lang.* — see what each
bundles. (Don't toggle unless you want it.) Then open lazyvim.json to
see the 'extras' array that drives it."
}

# ----------------------------------------------------------------- keymaps
lesson_keymaps() {
  brief "LazyVim keymaps, the conventions:

  - Your extra maps go in lua/config/keymaps.lua with vim.keymap.set.
  - LazyVim's defaults are discoverable: <space> opens which-key; sk
    searches all keymaps. Don't memorize — search.
  - which-key GROUPS: register a leader prefix label so menus read well.
    In a plugin spec for which-key:
      opts = { spec = { { '<leader>c', group = 'code' } } }
  - To CHANGE a LazyVim default key, you often override the plugin's
    keys = {} (set the old lhs to false to delete it, then add yours).
    Setting an lhs's rhs to false in a keys spec removes that mapping.

The leader is <space>; localleader is set too. Always pass desc so your
maps show up labeled in which-key."

  quiz "File for your own extra keymaps?" "keymaps.lua|lua/config/keymaps.lua" ""
  quiz "Search every keymap from inside nvim?" "space sk|<leader>sk|sk" ""
  quiz "Plugin that draws the leader menu?" "which-key|which-key.nvim" ""
  quiz "In a keys spec, how do you DELETE a default mapping?" "false|set rhs to false|= false" \
    "{ '<leader>x', false } removes LazyVim's <leader>x"
  quiz "Keymap opt that labels it in which-key?" "desc" ""
}

# --------------------------------------------------------------- mechanics
lesson_mechanics() {
  brief "lazy.nvim, the engine under LazyVim:

  :Lazy            the dashboard — install/update/clean/profile
  :Lazy sync       install missing + update + clean removed
  :Lazy update     update plugins (writes lazy-lock.json)
  :Lazy restore    roll everything back to the lockfile
  :Lazy profile    startup cost per plugin — find the slow ones
  :Lazy reload X   hot-reload a plugin while developing

LAZY TRIGGERS keep startup fast — a plugin loads only when its trigger
fires:
  event = 'VeryLazy'   after UI is up (most things)
  ft = 'rust'          on that filetype
  cmd = 'Telescope'    on first use of the command
  keys = { '<leader>x' } on first press
  lazy = false         load at startup (use sparingly — smart-splits
                       needs it to flag the kitty window early)

The lockfile makes your setup reproducible: commit lazy-lock.json."

  quiz "Open the plugin manager dashboard?" "Lazy|:Lazy" ""
  quiz "Install missing + update + clean in one go?" "Lazy sync|:Lazy sync" ""
  quiz "See per-plugin startup cost?" "Lazy profile|:Lazy profile" ""
  quiz "Trigger meaning 'after the UI is ready'?" "VeryLazy" ""
  quiz "Force a plugin to load at startup?" "lazy=false|lazy = false" \
    "your smart-splits spec uses this to set IS_NVIM early"
  quiz "File that makes the plugin set reproducible?" "lazy-lock.json|lockfile" ""

  guided "Real nvim: :Lazy, then press P for the profile view — see what
costs startup time. Esc, then :Lazy reload is how you'd iterate on a
plugin you're writing (course 92)."
}

# ------------------------------------------------------------------- drills
drills() {
  add_quiz "Folder for new plugin specs?" "lua/plugins|plugins"
  add_quiz "Your option overrides file?" "options.lua"
  add_quiz "Enabled extras file?" "lazyvim.json"
  add_quiz "Plugin lockfile?" "lazy-lock.json"
  add_quiz "First element of a spec?" "the repo|repo"
  add_quiz "Field that becomes setup(opts)?" "opts"
  add_quiz "Disable a plugin?" "enabled=false|enabled"
  add_quiz "Override that deep-merges options?" "opts table|table"
  add_quiz "Override to append to a list?" "opts function|function"
  add_quiz "Append to a list option?" "vim.list_extend"
  add_quiz "Browse/toggle extras?" "LazyExtras"
  add_quiz "Language support extra family?" "lang"
  add_quiz "Search all keymaps?" "space sk|sk"
  add_quiz "Delete a default mapping in a keys spec?" "false"
  add_quiz "Leader menu plugin?" "which-key"
  add_quiz "Open the plugin manager?" "Lazy|:Lazy"
  add_quiz "Install+update+clean?" "Lazy sync"
  add_quiz "Per-plugin startup cost?" "Lazy profile"
  add_quiz "Trigger after UI is up?" "VeryLazy"
  add_quiz "Force load at startup?" "lazy=false"
}
