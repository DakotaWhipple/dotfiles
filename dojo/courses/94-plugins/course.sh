# Course: the Neovim plugin ecosystem — what each one is and why.
COURSE_TITLE="The Plugin Ecosystem"
COURSE_DESC="A guided tour of the plugins that matter — the ones in your
LazyVim and the ones you'll reach for. What each does, the keys, and
when to pick one over another. Breadth, so nothing is a mystery."

LESSONS=(
  "find:Finding — pickers & fuzzy search"
  "lsp:LSP, mason, formatting, linting"
  "cmp:Completion & snippets"
  "edit:Editing — mini, flash, surround"
  "git:Git integration"
  "ui:UI — snacks, noice, statusline"
  "code:Coding — treesitter, trouble, dap"
)

# -------------------------------------------------------------------- find
lesson_find() {
  brief "FUZZY PICKERS are how you find anything. The landscape:

  snacks.picker   LazyVim's DEFAULT now (folke/snacks.nvim). Fast, no
                  external deps. Powers space space, space /, space sk.
  telescope.nvim  the classic, huge extension ecosystem; needs plenary
                  + fzf-native for speed.
  fzf-lua         thin, blazing wrapper around the fzf binary.

You're on snacks. The keys (all <space> first):
  space space   files     space /   live grep     space ,   buffers
  space sk      keymaps   space sh   help          space sr  resume
  space sg      grep      space :    command history
Inside a picker: ctrl-n/p or j/k move, ctrl-v vsplit, ctrl-q -> quickfix."

  quiz "LazyVim's default picker now?" "snacks|snacks.picker|snacks.nvim" ""
  quiz "The classic picker with the big extension ecosystem?" "telescope|telescope.nvim" ""
  quiz "Picker that's a thin wrapper over the fzf binary?" "fzf-lua|fzflua" ""
  quiz "Find files / live grep / search keymaps?" "space space, space /, space sk|spacespace space/ spacesk" \
    "say them as a set — these three carry most of your searching"
  quiz "Send picker results to the quickfix list?" "ctrl-q" ""
}

# --------------------------------------------------------------------- lsp
lesson_lsp() {
  brief "The LSP stack — four layers, each its own plugin:

  nvim-lspconfig    base configs for ~200 language servers
  mason.nvim        installs servers/formatters/linters (:Mason UI)
  mason-lspconfig   bridges the two (auto-enable installed servers)
  conform.nvim      FORMAT on save (prettier, stylua, ruff...)
  nvim-lint         LINT (eslint_d, shellcheck...) — diagnostics

LazyVim wires all of this; you mostly add servers via Extras. Keys:
  gd definition  gr references  gI implementation  K hover
  space cr rename  space ca code action  space cf format
  ]d / [d next/prev diagnostic   space cd line diagnostics

The LspAttach event is where buffer-local LSP keymaps get set — that's
the seam if you ever customize."

  quiz "Plugin holding configs for ~200 servers?" "nvim-lspconfig|lspconfig" ""
  quiz "Plugin that INSTALLS servers/tools?" "mason|mason.nvim" ""
  quiz "Plugin for format-on-save?" "conform|conform.nvim" ""
  quiz "Plugin for linting (diagnostics)?" "nvim-lint|lint" ""
  quiz "Rename a symbol / code action?" "space cr, space ca|spacecr spaceca" ""
  quiz "Event where LSP buffer keymaps attach?" "LspAttach" ""
}

# --------------------------------------------------------------------- cmp
lesson_cmp() {
  brief "Autocompletion as you type:

  blink.cmp     LazyVim's DEFAULT completion now — Rust-fast fuzzy,
                minimal config, batteries included.
  nvim-cmp      the long-time standard; pluggable 'sources'
                (cmp-buffer, cmp-path, cmp-nvim-lsp...).
  LuaSnip       snippet engine; friendly-snippets ships a big library.

The menu appears while typing. Defaults you can rely on:
  keep typing to filter, enter or ctrl-y accepts, ctrl-e dismisses,
  tab / shift-tab jump snippet placeholders, ctrl-space forces it open.
Sources = where suggestions come from: LSP, buffer words, paths,
snippets. blink bundles these; with nvim-cmp you wire each."

  quiz "LazyVim's default completion engine now?" "blink|blink.cmp" ""
  quiz "The older pluggable-sources completion plugin?" "nvim-cmp|cmp" ""
  quiz "Snippet engine commonly paired with completion?" "luasnip|LuaSnip" ""
  quiz "Accept the highlighted completion?" "enter|ctrl-y|cr" ""
  quiz "In nvim-cmp terms, where suggestions come from are called?" "sources" \
    "LSP, buffer, path, snippets — each a source"
}

# -------------------------------------------------------------------- edit
lesson_edit() {
  brief "Editing superpowers (mostly the mini.nvim family + flash):

  mini.pairs      auto-closes ) ] \" '
  mini.surround   add/change/delete surroundings:
                  gsa<motion><char> add, gsd<char> delete, gsr change
  mini.ai         smarter a/i textobjects (aq quotes, af function...)
  mini.comment / ts-comments   gcc line, gc motion (treesitter-aware)
  flash.nvim      s + 2 chars + label = jump anywhere; works as an
                  operator target (ds<chars>) and for treesitter (S)
  nvim-autopairs  alternative to mini.pairs

Note LazyVim's surround uses the gs* prefix (gsa/gsd/gsr), not the
classic vim-surround ys/cs/ds. Muscle-memory check: gsa i\" wraps."

  quiz "Plugin suite providing pairs, surround, ai, comment?" "mini|mini.nvim" ""
  quiz "LazyVim surround: ADD surrounding (prefix)?" "gsa|gsa<motion><char>" \
    "gsd delete, gsr replace — the gs* family"
  quiz "Comment a line / a motion?" "gcc, gc|gcc gc" ""
  quiz "Flash jump key?" "s" ""
  quiz "Flash for treesitter node selection?" "S" "expanding syntax-aware selection"
}

# --------------------------------------------------------------------- git
lesson_git() {
  brief "Git inside the editor:

  gitsigns.nvim   the gutter signs + hunk ops. Keys (LazyVim):
                  ]h / [h  next/prev hunk
                  space ghs stage hunk   space ghr reset hunk
                  space ghp preview hunk  space ghb blame line
  lazygit         full TUI; space gg opens it on the repo (snacks
                  launches it in a float). The fastest way to stage/
                  commit/rebase visually.
  diffview.nvim   a real side-by-side diff & file-history view.
  snacks gitbrowse  space gB -> open the line on GitHub.

You use jj day-to-day, but these still shine for browsing diffs,
blaming a line, and staging hunks surgically."

  quiz "Plugin for gutter signs and hunk staging?" "gitsigns|gitsigns.nvim" ""
  quiz "Next / previous changed hunk?" "]h, [h|]h [h" ""
  quiz "Stage the hunk under the cursor?" "space ghs|<leader>ghs" ""
  quiz "Open the lazygit TUI?" "space gg|<leader>gg" ""
  quiz "Blame the current line?" "space ghb|<leader>ghb" ""
}

# ---------------------------------------------------------------------- ui
lesson_ui() {
  brief "The look-and-feel layer — much of it now ONE plugin:

  snacks.nvim     folke's mega-utility: dashboard, notifier (toasts),
                  bigfile, picker, indent guides, scratch, zen,
                  gitbrowse, lazygit float, statuscolumn, input. LazyVim
                  leans on it hard.
  noice.nvim      restyles the cmdline, messages, and popups (the fancy
                  centered command box).
  lualine.nvim    the statusline.    bufferline.nvim  the tab/buffer bar.
  which-key.nvim  the leader menu.   todo-comments  highlights TODO/FIX.
  trouble.nvim    a pretty list for diagnostics/refs/quickfix.

So 'where's my dashboard / notifications / indent lines?' -> snacks."

  quiz "folke's mega-utility (dashboard, notifier, picker...)?" "snacks|snacks.nvim" ""
  quiz "Plugin that restyles the cmdline & messages?" "noice|noice.nvim" ""
  quiz "The statusline plugin?" "lualine|lualine.nvim" ""
  quiz "Pretty list for diagnostics / references?" "trouble|trouble.nvim" ""
  quiz "Plugin that highlights TODO/FIX/HACK comments?" "todo-comments|todo-comments.nvim" ""

  guided "Real nvim: trigger a notification (:lua vim.notify('hi')) to see
snacks' notifier. Then :Trouble diagnostics to see the trouble list.
space sk if you forget any key — the editor documents itself."
}

# -------------------------------------------------------------------- code
lesson_code() {
  brief "Code intelligence & power tools:

  nvim-treesitter         the parser — highlight, indent, folds, and the
                          base for textobjects (deep dive: course 95).
  treesitter-context      sticky header showing the enclosing fn/class.
  nvim-treesitter-textobjects  af/if function, ac/ic class, aa/ia param.
  trouble.nvim            navigable diagnostics/quickfix/symbols.
  nvim-dap (+ dap-ui)     full DEBUGGER: breakpoints, step, inspect.
                          Enable via the dap.* Extra; space d* keys.
  todo-comments / aerial  symbol outline (aerial) + TODO nav.
  conform / nvim-lint     format + lint (also in the LSP lesson).

Most of these arrive via Extras — you rarely wire them by hand."

  quiz "Sticky header showing the current function/class?" "treesitter-context|context" ""
  quiz "Function textobject (around / inner)?" "af, if|af if" ""
  quiz "The debugger plugin?" "nvim-dap|dap" ""
  quiz "Enable the debugger via a LazyVim?" "extra|dap extra|Extras" "the dap.* extra family"
  quiz "Navigable diagnostics/quickfix list?" "trouble|trouble.nvim" ""

  guided "Real nvim, in a code file: put the cursor deep inside a function
and scroll — watch treesitter-context pin the signature at the top.
Try vaf (visual around function) — a treesitter textobject in action."
}

# ------------------------------------------------------------------- drills
drills() {
  add_quiz "LazyVim's default picker?" "snacks"
  add_quiz "The classic picker (big ecosystem)?" "telescope"
  add_quiz "Find files / grep / keymaps keys?" "space space, space /, space sk|spacespace space/ spacesk"
  add_quiz "Configs for ~200 LSP servers?" "nvim-lspconfig|lspconfig"
  add_quiz "Installs servers and tools?" "mason"
  add_quiz "Format on save plugin?" "conform"
  add_quiz "Linting plugin?" "nvim-lint"
  add_quiz "Default completion engine now?" "blink|blink.cmp"
  add_quiz "Snippet engine?" "luasnip"
  add_quiz "Suite: pairs/surround/ai/comment?" "mini|mini.nvim"
  add_quiz "LazyVim add-surround prefix?" "gsa"
  add_quiz "Flash jump key?" "s"
  add_quiz "Gutter signs + hunks plugin?" "gitsigns"
  add_quiz "Next git hunk?" "]h"
  add_quiz "Open lazygit?" "space gg"
  add_quiz "folke's mega-utility plugin?" "snacks"
  add_quiz "Restyles cmdline & messages?" "noice"
  add_quiz "Statusline plugin?" "lualine"
  add_quiz "Diagnostics list plugin?" "trouble"
  add_quiz "The debugger plugin?" "nvim-dap|dap"
  add_quiz "Sticky function header plugin?" "treesitter-context|context"
  add_quiz "Function textobject?" "af|af if"
}
