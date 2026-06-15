# Course: Lua — the language Neovim is configured in.
COURSE_TITLE="Lua: the Neovim Language"
COURSE_DESC="Everything in your nvim is Lua: config, plugins, keymaps,
autocmds. Master the language and the whole editor opens up. Hands-on
drills run your real Lua with 'nvim -l', so you write code, not trivia."

LESSONS=(
  "values:Values, locals, and nil"
  "tables:Tables — the one data structure"
  "functions:Functions, returns, closures"
  "control:Control flow and idioms"
  "strings:Strings and patterns"
  "vimapi:vim.* — talking to Neovim"
  "modules:require and the module pattern"
)

# ------------------------------------------------------------------ values
lesson_values() {
  brief "Lua has very few moving parts. Variables:

  local x = 10          a local (ALWAYS use local — bare names are global)
  local a, b = 1, 2     multiple assignment
  x = x + 1             reassign (no 'let', no types)

Types: nil, boolean, number, string, table, function. That's it.
nil means 'nothing / not set'. Only nil and false are falsy —
0 and '' (empty string) are both TRUE in Lua. Beginners trip on
this constantly.

  print(x)              prints to :messages
  vim.print(tbl)        pretty-prints tables (your debug friend)"

  quiz "Keyword to declare a variable scoped to the block?" "local" \
    "forget it and you create a global — a real bug source"
  quiz "Which two values are falsy in Lua?" "nil false|false nil|nil and false" \
    "0 and empty string are TRUTHY in Lua, unlike many languages"
  quiz "Function to pretty-print a table for debugging?" "vim.print|vim.inspect" \
    "print(vim.inspect(t)) is the long form; vim.print(t) is the shortcut"

  shell_task \
"Create answer.lua (run: nvim answer.lua) that computes 7 * 6 and
prints it. One print, the number 42 on its own line." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx 42' \
    "local n = 7 * 6   then   print(n)"
}

# ------------------------------------------------------------------ tables
lesson_tables() {
  brief "Tables are THE data structure — arrays, maps, objects, modules,
all one type.

  local arr = { 10, 20, 30 }     1-INDEXED: arr[1] is 10
  #arr                            length operator -> 3
  table.insert(arr, 40)          append
  local map = { name = 'koda', n = 5 }
  map.name  /  map['name']        same thing
  map.lang = 'lua'               add a key

Iterate:
  for i, v in ipairs(arr) do ... end     arrays, in order, stops at nil
  for k, v in pairs(map)  do ... end     all keys, any order

ipairs = numeric/array; pairs = everything. Mixing them up is
the #2 Lua bug after forgetting 'local'."

  quiz "Index of the FIRST element of a Lua array?" "1|one" \
    "Lua is 1-indexed — arr[1], not arr[0]"
  quiz "Operator for the length of an array table?" "#" ""
  quiz "Iterate an array IN ORDER?" "ipairs" ""
  quiz "Iterate ALL keys of a map (any order)?" "pairs" ""
  quiz "Append to an array table?" "table.insert" "table.insert(t, v)"

  shell_task \
"answer.lua: build the table { 4, 8, 15, 16, 23, 42 }, then print
the SUM of all its elements using a for loop. (Should print 108.)" \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx 108' \
    "local t = {4,8,15,16,23,42}  local s=0  for _,v in ipairs(t) do s=s+v end  print(s)"

  shell_task \
"answer.lua: given local cfg = { width = 80, tabs = 2, wrap = true }
print just the value of cfg.width (prints 80)." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx 80' \
    "print(cfg.width)"
}

# --------------------------------------------------------------- functions
lesson_functions() {
  brief "Functions are values you can pass around.

  local function add(a, b) return a + b end
  local mul = function(a, b) return a * b end     anonymous, assigned

Multiple returns — Lua does this natively:
  local function minmax(t) return t[1], t[#t] end
  local lo, hi = minmax({3, 9})                   lo=3, hi=9

Varargs and closures:
  local function sum(...) local s=0 for _,v in ipairs({...}) do s=s+v end return s end
  local function counter() local n=0 return function() n=n+1 return n end end

The colon: obj:method() passes obj as the hidden first arg 'self'.
That is the ONLY difference between . and : on a table function."

  quiz "Keyword that returns value(s) from a function?" "return" ""
  quiz "Can a Lua function return more than one value?" "yes|true" \
    "local a, b = f() captures two; extras are discarded"
  quiz "obj:method() vs obj.method() — what does : add?" "self|self arg|the self argument" \
    "colon passes the table as the implicit first parameter 'self'"

  shell_task \
"answer.lua: write add(a, b) returning a+b AND a function counter()
that returns an incrementing closure. Print add(2,3), then print the
first three counter() calls. Expected lines: 5, then 1, 2, 3." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | tr "\n" " " | grep -q "5 1 2 3"' \
    "local c = counter()  print(c()) print(c()) print(c())"
}

# ----------------------------------------------------------------- control
lesson_control() {
  brief "Control flow — note 'end', 'elseif', '~=' (not ==):

  if x > 0 then ... elseif x == 0 then ... else ... end
  for i = 1, 10 do ... end           numeric (inclusive both ends)
  for i = 10, 1, -1 do ... end       step backwards
  while cond do ... end
  not / and / or                     no &&  ||  !

The famous idiom (Lua has no ternary):
  local label = ok and 'yes' or 'no'     ok ? 'yes' : 'no'
  local name = opts.name or 'default'    fallback when nil/false

'~=' is not-equal. '..' concatenates strings. Beginners type !=
and += — neither exists in Lua."

  quiz "Lua's not-equal operator?" "~=" "!= does not exist in Lua"
  quiz "Logical AND keyword (not &&)?" "and" ""
  quiz "Ternary-style default: name = opts.name __ 'def'" "or" \
    "x or y returns x unless it's nil/false, else y"
  quiz "Operator to concatenate two strings?" ".." "a .. b — not + (that's math)"

  shell_task \
"answer.lua: print the numbers 1..20, but for multiples of 3 print
'fizz' instead. Use a for loop and the modulo operator %. Line 3 and
line 6 etc should read fizz." \
    'out=$(nvim -l answer.lua 2>&1 | tr -d "\r"); echo "$out" | sed -n 3p | grep -qx fizz && echo "$out" | sed -n 6p | grep -qx fizz && echo "$out" | sed -n 20p | grep -qx 20' \
    "for i=1,20 do if i % 3 == 0 then print('fizz') else print(i) end end"
}

# ----------------------------------------------------------------- strings
lesson_strings() {
  brief "Strings: single or double quotes (identical), [[ ]] for
multi-line/raw.

  ('hi'):upper()           HI     — methods via the string library
  string.format('%d/%d', 1, 2)    '1/2'
  #s                       byte length
  s:sub(1, 3)              substring (1-indexed, inclusive)
  s:find('foo')            returns start,end or nil
  s:gsub('a', 'b')         replace, returns new string + count

Lua PATTERNS are not regex — similar but their own thing:
  %d digit  %a letter  %s space  %w alnum   . any   * + - ?  quantifiers
  s:match('(%d+)')         capture the first run of digits

For config you mostly use format, gsub, match, sub."

  quiz "Format a string like printf?" "string.format|format" ""
  quiz "Replace text in a string (returns new string)?" "gsub|string.gsub|s:gsub" ""
  quiz "Are Lua patterns the same as regex?" "no|false" \
    "they're Lua's own mini-language: %d %a %w %s, not \\d \\w"
  quiz "Pattern class for a digit?" "%d" "%a letter, %s space, %w alphanumeric"

  shell_task \
"answer.lua: given local path = '/home/koda/init.lua', print just the
filename 'init.lua'. Hint: path:match('[^/]+\$')  (or string.gsub)." \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx "init.lua"' \
    "print(path:match('[^/]+$'))   -- everything after the last slash"
}

# ------------------------------------------------------------------ vimapi
lesson_vimapi() {
  brief "The 'vim' global is your handle on the editor. The big ones:

  vim.opt.number = true        options (vim.o also works; opt is richer)
  vim.g.mapleader = ' '        global vars (plugin settings live here)
  vim.keymap.set(...)          mappings (next course)
  vim.api.nvim_*               the raw C API — buffers, windows, lines
  vim.fn.expand('%:p')         call ANY vimscript function from Lua
  vim.cmd('write')             run an Ex command / vimscript
  vim.notify('hi', vim.log.levels.WARN)   toasts (snacks themes these)

vim.fn is the bridge to 30 years of vimscript builtins. vim.api is
the modern, fast, structured interface. You'll use both."

  quiz "Set an option like 'number' from Lua?" "vim.opt|vim.o|vim.opt.number" ""
  quiz "Where does mapleader get set?" "vim.g|vim.g.mapleader" \
    "vim.g.* is global vim variables — many plugins read their config here"
  quiz "Call a vimscript builtin like expand() from Lua?" "vim.fn|vim.fn.expand" ""
  quiz "Run an Ex command (like :write) from Lua?" "vim.cmd|vim.cmd()" ""
  quiz "The structured C-level API namespace?" "vim.api" "vim.api.nvim_... functions"

  shell_task \
"answer.lua: use vim.fn.fnamemodify to print the TAIL (filename) of
'/etc/nvim/init.lua'. Expected: init.lua.  (':t' is the tail modifier.)" \
    'nvim -l answer.lua 2>&1 | tr -d "\r" | grep -qx "init.lua"' \
    "print(vim.fn.fnamemodify('/etc/nvim/init.lua', ':t'))"
}

# ------------------------------------------------------------------ modules
lesson_modules() {
  brief "A Lua MODULE is a file that returns a table. This is how every
plugin and your own config is organized.

  -- lua/mything/init.lua
  local M = {}
  function M.hello() return 'hi' end
  return M

Then anywhere:
  local mything = require('mything')      finds lua/mything/init.lua
  mything.hello()

require SEARCHES your runtimepath's lua/ folders and CACHES the result
(package.loaded) — the file runs once. require('a.b') maps to
lua/a/b.lua  or  lua/a/b/init.lua. Dots are folders.

This 'local M = {} ... return M' pattern is the heartbeat of the next
two courses (the API and authoring plugins)."

  quiz "A Lua module file must ___ a table." "return" ""
  quiz "Function to load a module by name?" "require|require()" ""
  quiz "require('foo.bar') maps to which file?" "lua/foo/bar.lua|foo/bar.lua|lua/foo/bar" \
    "or lua/foo/bar/init.lua — dots are directory separators"
  quiz "How many times does a required file run (it's cached)?" "once|1|one" \
    "package.loaded caches it; a second require returns the same table"

  shell_task \
"Build a real module. Make a folder 'greet' containing greet/init.lua
that returns a table M with a function M.name() returning 'koda'. The
check requires('greet') and calls name() — so it must return the table." \
    'printf "package.path=\"./?/init.lua;./?.lua;\"..package.path\nprint(require(\"greet\").name())\n" > .run.lua && nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx koda' \
    "greet/init.lua: local M = {}  function M.name() return 'koda' end  return M"
}

# ------------------------------------------------------------------- drills
drills() {
  add_quiz "Declare a block-scoped variable?" "local"
  add_quiz "The two falsy values in Lua?" "nil false|false nil"
  add_quiz "First array index in Lua?" "1"
  add_quiz "Length operator?" "#"
  add_quiz "Iterate an array in order?" "ipairs"
  add_quiz "Iterate all map keys?" "pairs"
  add_quiz "Append to an array?" "table.insert"
  add_quiz "Not-equal operator?" "~="
  add_quiz "Logical AND keyword?" "and"
  add_quiz "String concatenation operator?" ".."
  add_quiz "Pretty-print a table?" "vim.print|vim.inspect"
  add_quiz "Set an option from Lua?" "vim.opt|vim.o"
  add_quiz "Call a vimscript function from Lua?" "vim.fn"
  add_quiz "Run an Ex command from Lua?" "vim.cmd"
  add_quiz "Load a module?" "require"
  add_quiz "A module file must do what?" "return a table|return"
  add_quiz "Format a string printf-style?" "string.format|format"
  add_quiz "Pattern class for a digit?" "%d"
  add_quiz "Default-value idiom: x __ fallback" "or"
  add_quiz "Where plugin globals live?" "vim.g"
}
