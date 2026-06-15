# Course: authoring Neovim plugins from scratch.
COURSE_TITLE="Author a Neovim Plugin"
COURSE_DESC="Go from 'I configure plugins' to 'I write plugins'. You'll
build a real one — module, setup(), config merge, commands, health
check — and run it with nvim. This is the master-class on plugin guts."

LESSONS=(
  "anatomy:Plugin anatomy & runtimepath"
  "module:The module + setup pattern"
  "config:Merging user options"
  "expose:Commands, keymaps, the contract"
  "startup:plugin/ vs lua/ and load guards"
  "health:Health checks & docs"
  "lazyspec:How lazy.nvim loads your plugin"
)

# ----------------------------------------------------------------- anatomy
lesson_anatomy() {
  brief "A plugin is just a directory ON THE RUNTIMEPATH with magic
folders. nvim scans every dir in :set rtp? for these:

  lua/<name>/init.lua    your code — loaded ONLY when require'd
  plugin/<name>.lua      runs automatically AT STARTUP (once)
  ftplugin/<lang>.lua    runs when a buffer's filetype = lang
  after/                 runs LAST (override other plugins/queries)
  doc/<name>.txt         help; :helptags makes :h <tag> work
  queries/<lang>/*.scm   treesitter queries (course 95)

So the split is: put the BODY in lua/ (lazy, require'd), put a tiny
STARTUP hook in plugin/ if you need one. Plugin managers like lazy.nvim
just clone your repo into a dir and add it to the runtimepath."

  quiz "Folder whose files run automatically at startup?" "plugin|plugin/" ""
  quiz "Folder for code that loads only when require'd?" "lua|lua/" ""
  quiz "What must a dir be ON for nvim to see its plugin folders?" "runtimepath|rtp|the runtimepath" ""
  quiz "Folder that loads per-filetype?" "ftplugin|ftplugin/" ""
  quiz "Folder that loads LAST, for overrides?" "after|after/" ""
}

# ------------------------------------------------------------------ module
lesson_module() {
  brief "Every plugin's lua/<name>/init.lua follows ONE pattern:

  local M = {}
  function M.setup(opts) end        -- the entry point convention
  function M.hello() print('hi') end
  return M

Users then: require('name').setup({ ... }). The 'M = {} ... return M'
shape is the entire skeleton. setup() is just a CONVENTION (lazy.nvim's
opts= calls it for you) — your job is to make it the place that reads
options and wires things up.

Below you'll create lua/hello/init.lua with this exact skeleton."

  quiz "Conventional entry-point function name?" "setup|M.setup" ""
  quiz "The two lines that bracket every module?" "local M = {} and return M|M={} return M|return M" \
    "local M = {} at the top, return M at the bottom"
  quiz "Who calls setup() when using lazy.nvim's opts field?" "lazy|lazy.nvim|the plugin manager" \
    "opts = {...} makes lazy call require(name).setup(opts) for you"

  shell_task \
"Create lua/hello/init.lua with the skeleton: local M = {}, a function
M.setup(opts) (can be empty), a function M.greet(name) that returns
'Hello, ' .. name, and return M at the end." \
    'printf "package.path=\"./lua/?/init.lua;./lua/?.lua;./?/init.lua;./?.lua;\"..package.path\nprint(require(\"hello\").greet(\"koda\"))\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx "Hello, koda"' \
    "mkdir -p lua/hello; put the skeleton in lua/hello/init.lua. greet returns 'Hello, '..name"
}

# ------------------------------------------------------------------ config
lesson_config() {
  brief "Good plugins ship DEFAULTS and let users override a subset.
The idiom is vim.tbl_deep_extend:

  local defaults = { greeting = 'Hello', loud = false }
  function M.setup(opts)
    M.opts = vim.tbl_deep_extend('force', defaults, opts or {})
  end

'force' means later tables win on conflicts. 'opts or {}' guards the
case where the user calls setup() with no args. Now M.opts is the
merged config the rest of your code reads. NEVER mutate 'defaults'
directly — always merge into a new table.

Make greet() respect the merged greeting below."

  quiz "Function that deep-merges option tables?" "vim.tbl_deep_extend|tbl_deep_extend" ""
  quiz "First arg to tbl_deep_extend so later tables win?" "force|'force'" \
    "'keep' keeps the first; 'error' throws on conflict"
  quiz "Guard so setup() with no args doesn't crash?" "opts or {}|or {}" ""

  shell_task \
"Rewrite lua/hello/init.lua: defaults = { greeting = 'Hello' }.
setup(opts) merges into M.opts with tbl_deep_extend('force', ...).
greet(name) returns M.opts.greeting .. ', ' .. name. The check calls
setup({ greeting = 'Hi' }) then greet('koda') — expects 'Hi, koda'." \
    'printf "package.path=\"./lua/?/init.lua;./lua/?.lua;./?/init.lua;./?.lua;\"..package.path\nlocal h=require(\"hello\")\nh.setup({greeting=\"Hi\"})\nprint(h.greet(\"koda\"))\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx "Hi, koda"' \
    "M.opts = vim.tbl_deep_extend('force', defaults, opts or {}) ; greet uses M.opts.greeting"
}

# ------------------------------------------------------------------ expose
lesson_expose() {
  brief "How a plugin offers itself to the user — and the etiquette:

  COMMANDS: define them in setup().
    vim.api.nvim_create_user_command('Hello', function() ... end, {})

  KEYMAPS: provide them but DON'T force them. Good plugins expose
    functions and <Plug> mappings and let the USER bind keys:
    vim.keymap.set('n', '<Plug>(HelloGreet)', M.greet)
    ...then the user maps <leader>h to <Plug>(HelloGreet) if they want.
    Stomping on a user's keys without an opt is rude (and a bug magnet).

The contract: setup() reads opts, creates commands/autocmds, exposes
functions. Keep require'ing cheap — heavy work goes in setup or lazy
require, never at module top-level."

  quiz "Where should a plugin create its :Commands?" "setup|in setup|M.setup" ""
  quiz "Mechanism to expose an action for users to map themselves?" "<Plug>|plug|plug mapping" \
    "<Plug>(Name) mappings let users choose their own lhs"
  quiz "Should a plugin force keymaps on the user by default?" "no|false" \
    "expose functions/<Plug>; let the user (or lazy's keys=) bind"

  shell_task \
"Make setup() in lua/hello/init.lua ALSO create a user command :Hello.
The check runs setup() then asks nvim whether the command exists." \
    'printf "package.path=\"./lua/?/init.lua;./lua/?.lua;./?/init.lua;./?.lua;\"..package.path\nrequire(\"hello\").setup()\nprint(vim.api.nvim_get_commands({})[\"Hello\"] and \"ok\" or \"no\")\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx ok' \
    "inside setup: vim.api.nvim_create_user_command('Hello', function() end, {})"
}

# ----------------------------------------------------------------- startup
lesson_startup() {
  brief "plugin/<name>.lua runs at EVERY startup, before any require.
Use it ONLY for things that must exist immediately (a command that
lazy-loads the rest, a global autocmd). And GUARD it so it runs once:

  -- plugin/hello.lua
  if vim.g.loaded_hello then return end
  vim.g.loaded_hello = true
  vim.api.nvim_create_user_command('Hello', function()
    require('hello').greet('world')   -- NOW the heavy lua loads
  end, {})

This is the lazy-loading trick by hand: a tiny startup stub that
require()s the real code on first use. lua/ stays cold until needed.
Most modern plugins lean on the plugin manager for this instead."

  quiz "File that runs automatically at every startup?" "plugin/hello.lua|plugin/<name>.lua|plugin file" ""
  quiz "Variable convention to guard against double-loading?" "vim.g.loaded_|vim.g.loaded_hello|loaded guard" \
    "if vim.g.loaded_x then return end ; vim.g.loaded_x = true"
  quiz "Trick to keep lua/ cold until first use?" "require in the command|lazy require|require on demand" \
    "the startup stub require()s the body only when the command runs"
}

# ------------------------------------------------------------------ health
lesson_health() {
  brief "':checkhealth hello' should tell users if your plugin is happy.
Add lua/hello/health.lua returning a check():

  local M = {}
  function M.check()
    vim.health.start('hello')
    if vim.fn.executable('rg') == 1 then
      vim.health.ok('ripgrep found')
    else
      vim.health.warn('ripgrep missing', { 'brew install ripgrep' })
    end
  end
  return M

:checkhealth hello finds lua/hello/health.lua automatically. The API:
vim.health.start / ok / warn / error / info. Great plugins validate
their deps and config here so users self-diagnose."

  quiz "Command users run to diagnose a plugin?" "checkhealth|:checkhealth" ""
  quiz "File a plugin adds for health checks?" "health.lua|lua/hello/health.lua" ""
  quiz "Function to report a passing check?" "vim.health.ok|health.ok|ok" \
    "also .start .warn .error .info"

  shell_task \
"Add lua/hello/health.lua returning M with M.check() that calls
vim.health.start('hello') and vim.health.ok('all good'). The check
runs M.check() and confirms it doesn't error (prints done)." \
    'printf "package.path=\"./lua/?/init.lua;./lua/?.lua;./?/init.lua;./?.lua;\"..package.path\nrequire(\"hello.health\").check()\nprint(\"done\")\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx done' \
    "lua/hello/health.lua: local M={} function M.check() vim.health.start('hello') vim.health.ok('all good') end return M"
}

# ---------------------------------------------------------------- lazyspec
lesson_lazyspec() {
  brief "Your plugin meets the world as a lazy.nvim SPEC — a table in
~/.config/nvim/lua/plugins/*.lua:

  return {
    'koda/hello.nvim',          -- the repo (or a local dir/dev path)
    opts = { greeting = 'Hi' }, -- lazy calls require('hello').setup(opts)
    cmd = 'Hello',              -- lazy-load when :Hello is first run
    keys = { { '<leader>h', '<cmd>Hello<cr>', desc = 'Hello' } },
    ft = 'lua',                 -- or load on a filetype
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function(_, opts) require('hello').setup(opts) end, -- manual
  }

opts vs config: opts is shorthand (lazy runs setup(opts)); config is the
full-control version. cmd/keys/ft/event are LAZY TRIGGERS — the plugin
stays unloaded until one fires. That's why startup stays fast."

  quiz "Field that becomes setup(opts) automatically?" "opts" ""
  quiz "Field for full control over how setup is called?" "config" \
    "config = function(_, opts) ... end runs your own init code"
  quiz "Lazy-load a plugin when a command is first used?" "cmd|cmd=" ""
  quiz "Lazy-load on a keypress?" "keys|keys=" ""
  quiz "Declare another plugin yours needs first?" "dependencies|dependencies=" ""
  quiz "Lazy-load on entering a filetype?" "ft|ft=|event" ""

  guided "In real nvim: :Lazy opens the plugin manager UI. Find a plugin,
press a profile to see load time, K to see its spec. Look at a few
specs in ~/.config/nvim/lua/plugins to see opts/keys/event in the wild."
}

# ------------------------------------------------------------------- drills
drills() {
  add_quiz "Folder that runs at startup?" "plugin"
  add_quiz "Folder loaded only on require?" "lua"
  add_quiz "Folder that loads last (overrides)?" "after"
  add_quiz "Per-filetype folder?" "ftplugin"
  add_quiz "Conventional entry function?" "setup"
  add_quiz "Module brackets: top and bottom lines?" "local M = {} and return M|M={} return M"
  add_quiz "Deep-merge option tables?" "vim.tbl_deep_extend"
  add_quiz "Merge mode where later wins?" "force"
  add_quiz "Guard for setup() with no args?" "opts or {}"
  add_quiz "Create a user command?" "nvim_create_user_command"
  add_quiz "Expose an action for users to map?" "<Plug>|plug"
  add_quiz "Guard variable against double-load?" "vim.g.loaded_|loaded guard"
  add_quiz "Diagnose a plugin?" "checkhealth"
  add_quiz "Health file name?" "health.lua"
  add_quiz "Report a passing health check?" "vim.health.ok|ok"
  add_quiz "Lazy field that becomes setup(opts)?" "opts"
  add_quiz "Full-control load field?" "config"
  add_quiz "Lazy-load on a command?" "cmd"
  add_quiz "Lazy-load on a key?" "keys"
  add_quiz "Declare plugin prerequisites?" "dependencies"
}
