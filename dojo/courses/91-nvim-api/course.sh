# Course: the Neovim API — options, keymaps, autocmds, buffers, commands.
COURSE_TITLE="Neovim: the API & Editor Model"
COURSE_DESC="The vocabulary every config and plugin speaks: options,
keymaps, autocommands, the buffer/window/tab model, and user commands.
Get fluent here and you can bend nvim to anything."

LESSONS=(
  "options:Options — opt, o, bo, wo"
  "keymaps:Keymaps with vim.keymap.set"
  "autocmds:Autocommands and augroups"
  "buffers:Buffers, windows, tabs, lines"
  "commands:User commands"
  "diag:Diagnostics, notify, schedule"
)

# ----------------------------------------------------------------- options
lesson_options() {
  brief "Options have THREE scopes. Pick the right tool:

  vim.opt.shiftwidth = 2       global-ish, and 'opt' gives table powers:
  vim.opt.wildignore:append('*.o')      list options append/remove/prepend
  vim.o.number = true          simple scalar set (string/number/bool)
  vim.bo.filetype              BUFFER-local options
  vim.wo.wrap = false          WINDOW-local options

Rule of thumb: vim.opt for anything list/flag-like (it returns a rich
object); vim.o for a quick scalar. bo/wo when you specifically mean
this buffer or window (e.g. inside an autocmd or ftplugin).

  :set opt?     in nvim shows the current value — your inspector."

  quiz "Richest way to set an option (supports :append/:remove)?" "vim.opt|vim.opt.x" ""
  quiz "Set a BUFFER-local option?" "vim.bo|vim.bo.x" ""
  quiz "Set a WINDOW-local option?" "vim.wo|vim.wo.x" ""
  quiz "Append to a list option like wildignore?" "vim.opt.x:append|:append|append" \
    "vim.opt.wildignore:append('*.pyc') — vim.o can't do this"

  shell_task \
"answer.lua: set vim.opt.shiftwidth to 4, then print its value via
vim.opt.shiftwidth:get() (prints 4)." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx 4' \
    "vim.opt.shiftwidth = 4   then   print(vim.opt.shiftwidth:get())"
}

# ----------------------------------------------------------------- keymaps
lesson_keymaps() {
  brief "vim.keymap.set(mode, lhs, rhs, opts) — the one true mapper:

  vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save' })
  vim.keymap.set('n', '<leader>x', function() print('hi') end)
  vim.keymap.set({ 'n', 'v' }, 'gh', '0', { desc = 'Line start' })

modes: n normal, i insert, v visual, x visual-only, o operator, t terminal.
rhs can be a STRING (keys/command) or a Lua FUNCTION (just pass it).
opts that matter:
  desc      shows in which-key + :map — ALWAYS add one
  silent    don't echo the command
  buffer    = true or bufnr — map only in this buffer
  expr      rhs returns the keys to run (dynamic maps)
  remap     allow recursive mapping (default is noremap)

Delete one: vim.keymap.del('n', '<leader>w')."

  quiz "The modern function to create a keymap?" "vim.keymap.set|keymap.set" ""
  quiz "Opt that gives the mapping a which-key label?" "desc" \
    "always set desc — it documents your config to future-you"
  quiz "Mode code for terminal mappings?" "t" ""
  quiz "Make a mapping apply only to the current buffer?" "buffer|buffer=true" ""
  quiz "rhs that computes the keys to send at press time uses opt?" "expr|expr=true" ""

  shell_task \
"answer.lua: create a normal-mode mapping <leader>h to the string 'echo'
with desc 'demo', then print the desc by reading it back from
vim.api.nvim_get_keymap('n'). (Print should contain 'demo'.) Tip:
loop the table, find the one whose .lhs matches your leader+h." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -q demo' \
    "set vim.g.mapleader=' ' first; lhs becomes ' h'. Then iterate get_keymap('n') and print m.desc"
}

# ---------------------------------------------------------------- autocmds
lesson_autocmds() {
  brief "Autocommands run Lua on EVENTS. The modern API:

  local grp = vim.api.nvim_create_augroup('MyStuff', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = grp,
    pattern = '*.lua',
    callback = function(args) --[[ args.buf, args.file ]] end,
  })

ALWAYS put autocmds in a named augroup with clear=true — otherwise
re-sourcing your config stacks duplicates. Events you'll use:
  BufWritePre/Post   around saving
  FileType           per-language setup (pattern = 'python')
  VimEnter           after startup
  LspAttach          when a language server attaches to a buffer
  TextYankPost       (the highlight-on-yank trick)

callback gets one table arg: { buf, file, match, data }."

  quiz "Create an autocommand (modern API)?" "nvim_create_autocmd|vim.api.nvim_create_autocmd" ""
  quiz "Group autocmds so re-sourcing doesn't duplicate them?" "augroup|nvim_create_augroup|vim.api.nvim_create_augroup" ""
  quiz "Option on the group that prevents stacking duplicates?" "clear|clear=true" ""
  quiz "Event that fires just BEFORE a buffer is written?" "BufWritePre" ""
  quiz "Event when an LSP server attaches to a buffer?" "LspAttach" \
    "the LazyVim way to set buffer-local LSP keymaps"

  shell_task \
"answer.lua: create an augroup 'T' (clear) and a User autocmd on
pattern 'Ping' whose callback prints 'pong'. Then fire it with
vim.api.nvim_exec_autocmds('User', { pattern = 'Ping' }). Prints pong." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx pong' \
    "callback = function() print('pong') end ; then nvim_exec_autocmds('User',{pattern='Ping'})"
}

# ----------------------------------------------------------------- buffers
lesson_buffers() {
  brief "The model: TABS hold WINDOWS (viewports) which display BUFFERS
(in-memory file contents). One buffer can show in many windows.

  vim.api.nvim_get_current_buf()          the active bufnr
  vim.api.nvim_list_bufs()                all buffers
  vim.api.nvim_buf_get_lines(0, 0, -1, false)   ALL lines (0 = current)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'new', 'text' })
  vim.api.nvim_win_get_cursor(0)          { row(1-based), col(0-based) }
  vim.api.nvim_get_current_win()          active window id

KEY GOTCHA: buffer LINES are 0-indexed and end-exclusive (0,-1 = all).
But the CURSOR row is 1-based while its col is 0-based. The API mixes
indexing on purpose — burn it in now."

  quiz "0 as a bufnr/winid argument means what?" "current|the current one|current buffer" ""
  quiz "Read all lines of a buffer?" "nvim_buf_get_lines|vim.api.nvim_buf_get_lines" ""
  quiz "Are nvim_buf_get_lines indices 0-based or 1-based?" "0-based|0|zero" \
    "0,-1,false grabs every line; end index is exclusive"
  quiz "Cursor from nvim_win_get_cursor: row is 1-based, col is?" "0-based|0|zero" \
    "the famous mismatch: {row1based, col0based}"

  shell_task \
"answer.lua: set the current buffer's lines to exactly three lines
'a','b','c' with nvim_buf_set_lines, then print how many lines the
buffer has (nvim_buf_line_count). Prints 3." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx 3' \
    "vim.api.nvim_buf_set_lines(0,0,-1,false,{'a','b','c'}) ; print(vim.api.nvim_buf_line_count(0))"
}

# ---------------------------------------------------------------- commands
lesson_commands() {
  brief "User commands are :Capitalized verbs you define.

  vim.api.nvim_create_user_command('Hi', function(opts)
    print('hi ' .. opts.args)
  end, { nargs = '?', desc = 'greet' })

  :Hi there      -> prints 'hi there'

opts fields you pass:
  nargs   0 / 1 / '?' (0-1) / '*' (any) / '+' (1+)
  bang    = true -> command can be :Hi!  (opts.bang is then true)
  range   accept a line range (opts.line1, opts.line2)
  complete  completion: 'file', 'buffer', or a function
  desc    description

Buffer-local version: nvim_buf_create_user_command(0, ...)."

  quiz "Create a :Command from Lua?" "nvim_create_user_command|vim.api.nvim_create_user_command" ""
  quiz "Field that lets the command take any number of args?" "nargs|nargs='*'" "'*' = any, '+' = one or more"
  quiz "Field to allow a :Cmd! bang variant?" "bang|bang=true" ""
  quiz "Must a user command name start with a capital letter?" "yes|true|uppercase" \
    "all user commands are Capitalized"

  shell_task \
"answer.lua: define a command :Double taking one arg (nargs=1) that
prints the number doubled, then call it via vim.cmd('Double 21').
Prints 42." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx 42' \
    "function(o) print(tonumber(o.args) * 2) end ; vim.cmd('Double 21')"
}

# -------------------------------------------------------------------- diag
lesson_diag() {
  brief "Three runtime helpers you'll reach for constantly:

  vim.notify('msg', vim.log.levels.WARN)    a toast (snacks styles it)
  vim.log.levels = { TRACE, DEBUG, INFO, WARN, ERROR }

  vim.schedule(function() ... end)          run SOON, on the main loop —
    required when you're in a fast-event context (some autocmd/LSP
    callbacks) and want to touch the UI/buffers safely.
  vim.defer_fn(fn, 200)                      run after 200ms

  vim.diagnostic.get(0)                     diagnostics for a buffer
  vim.diagnostic.config({ virtual_text = true })
  vim.diagnostic.goto_next()                (LazyVim maps ]d / [d)

If you ever see 'E5560: ... not allowed in fast event', the fix is to
wrap the body in vim.schedule(function() ... end)."

  quiz "Show a toast/notification from Lua?" "vim.notify|notify" ""
  quiz "Defer work safely onto the main loop?" "vim.schedule|schedule" \
    "the fix for 'not allowed in fast event' errors"
  quiz "Run a function after a delay in ms?" "vim.defer_fn|defer_fn" ""
  quiz "Namespace for errors/warnings under the cursor?" "vim.diagnostic|diagnostic" ""

  guided "In real nvim: open any file, :lua vim.notify('hello', vim.log.levels.WARN)
— watch snacks render the toast. Then :lua vim.print(vim.diagnostic.get(0))
on a file with an error to see the raw diagnostic table."
}

# ------------------------------------------------------------------- drills
drills() {
  add_quiz "Richest option setter?" "vim.opt"
  add_quiz "Buffer-local option?" "vim.bo"
  add_quiz "Window-local option?" "vim.wo"
  add_quiz "Append to a list option?" ":append|append"
  add_quiz "Create a keymap?" "vim.keymap.set"
  add_quiz "Keymap opt for a which-key label?" "desc"
  add_quiz "Map only in the current buffer?" "buffer"
  add_quiz "Create an autocommand?" "nvim_create_autocmd"
  add_quiz "Group that prevents duplicate autocmds?" "augroup|nvim_create_augroup"
  add_quiz "Group opt to avoid stacking?" "clear"
  add_quiz "Event before writing a buffer?" "BufWritePre"
  add_quiz "Event when LSP attaches?" "LspAttach"
  add_quiz "Read all buffer lines?" "nvim_buf_get_lines"
  add_quiz "Buffer line indices are __-based?" "0|0-based"
  add_quiz "0 as a bufnr means?" "current"
  add_quiz "Create a :Command?" "nvim_create_user_command"
  add_quiz "Arg-count field on a command?" "nargs"
  add_quiz "Show a notification toast?" "vim.notify"
  add_quiz "Defer onto the main loop?" "vim.schedule"
  add_quiz "Diagnostics namespace?" "vim.diagnostic"
}
