# Course: Treesitter — parse trees, textobjects, and queries.
COURSE_TITLE="Treesitter Mastery"
COURSE_DESC="Treesitter parses your code into a real syntax TREE — the
engine behind highlighting, indent, folds, and syntax-aware motions.
Learn to read the tree, use its textobjects, and WRITE queries. The
query drills run against nvim's live Lua parser."

LESSONS=(
  "concept:What treesitter actually is"
  "inspect:Reading the tree — Inspect"
  "textobjects:Syntax textobjects"
  "selection:Incremental selection & motions"
  "queries:Query language — captures & predicates"
  "writing:Write a query (hands-on)"
  "injections:Injections, folds, overrides"
)

# ----------------------------------------------------------------- concept
lesson_concept() {
  brief "Treesitter is a real PARSER, not regex. For each language a
GRAMMAR turns source text into a concrete syntax TREE of NODES. nvim
then uses that tree for:

  - highlighting   (precise: a function name vs a variable vs a keyword)
  - indentation
  - folding
  - textobjects & motions  (select 'the function', jump to 'next class')
  - incremental selection

Managing grammars (via nvim-treesitter):
  :TSInstall lua python      install a parser
  :TSUpdate                  update parsers
  ensure_installed = {...}   in the nvim-treesitter spec (declarative)
  :TSModuleInfo / :checkhealth nvim-treesitter

Some parsers (lua, vim, vimdoc, query, c, markdown) ship WITH nvim;
the rest install on demand. The tree updates as you type — incrementally,
so it's fast even on big files."

  quiz "Treesitter parses code into a ___?" "tree|syntax tree|parse tree" "of nodes, per the language grammar"
  quiz "Is treesitter based on regex?" "no|false" "it's a real grammar-driven parser"
  quiz "Install a parser for a language?" "TSInstall|:TSInstall" ""
  quiz "Declarative list of parsers to always have?" "ensure_installed" \
    "set it in the nvim-treesitter plugin opts"
  quiz "Name two things treesitter powers besides highlighting?" "indent and folds|folds, textobjects|indent folds motions" \
    "highlight, indent, folds, textobjects, selection"
}

# ----------------------------------------------------------------- inspect
lesson_inspect() {
  brief "To work WITH the tree you have to SEE it.

  :InspectTree     opens a live view of the syntax tree for the buffer
                   (older alias: :TSPlayground). Move your cursor in the
                   code — the matching node highlights in the tree.
  :Inspect         shows the highlight groups + treesitter captures
                   UNDER THE CURSOR (why is this token THIS color?).
  :EditQuery       open the query editor to experiment live.

Node vocabulary:
  named node     meaningful: (function_declaration), (identifier)
  anonymous node punctuation/keywords, written in quotes: \"(\" \"function\"
  field          a labeled child: name:, body:, condition: — fields let
                 you say 'the NAME child of a function', precisely.

In Lua, 'function foo()' parses to (function_declaration name: (identifier))
— a function_declaration whose name field is an identifier. You'll use
exactly that shape in the query lessons."

  quiz "Command to view the live syntax tree?" "InspectTree|:InspectTree" ""
  quiz "Command to see highlight/captures under the cursor?" "Inspect|:Inspect" ""
  quiz "Meaningful nodes like (identifier) are called?" "named|named nodes" ""
  quiz "Keywords/punctuation nodes (written in quotes) are?" "anonymous|anonymous nodes" ""
  quiz "A LABELED child like name: or body: is a?" "field" \
    "fields let a query target a specific child precisely"

  guided "Real nvim: open a lua file, :InspectTree (split opens). Move the
cursor over a function name and watch the tree highlight the node. Then
:Inspect on that token to see its capture (@function or @variable...)."
}

# ------------------------------------------------------------- textobjects
lesson_textobjects() {
  brief "Treesitter textobjects = select/operate on SYNTAX, not lines.
From nvim-treesitter-textobjects (LazyVim ships it). Use them after any
operator (d/c/y/v):

  af / if    A Function / Inner function   (vaf = select whole fn)
  ac / ic    A Class / inner class
  aa / ia    A parameter (Argument) / inner   (daa deletes an arg + comma)
  al / il    A Loop / inner   (config-dependent)
  ai / ii    A Conditional / inner

So: daf deletes the whole function. cif clears a function body. via
selects the parameter. vaa then > indents an argument. These beat
counting lines because they track the actual code structure.

(mini.ai extends this further with aq quotes, a? user prompts, etc.)"

  quiz "Select/operate on a whole function (around)?" "af|vaf|daf" "vaf, daf, yaf..."
  quiz "Inner function body textobject?" "if|cif" ""
  quiz "Around a class?" "ac" ""
  quiz "Textobject for a function PARAMETER / argument?" "aa|ia" "daa deletes the arg and its comma"
  quiz "Delete the entire function under the cursor?" "daf" ""

  guided "Real nvim, in a code file with a function: try vaf (selects the
whole function), then vif (just the body). Put the cursor in a call's
args and try via / daa. Feel how it tracks structure, not lines."
}

# ----------------------------------------------------------------- selection
lesson_selection() {
  brief "Two syntax-aware navigation tools:

INCREMENTAL SELECTION — grow/shrink the selection by tree node:
  <C-space>   start / EXPAND selection to the next bigger node
              (identifier -> call -> statement -> block -> function...)
  <bs>        SHRINK back to the smaller node
  (these are the nvim-treesitter incremental_selection defaults LazyVim
  uses; check space sk to confirm yours.)

TREESITTER MOTIONS (from -textobjects) — jump by structure:
  ]f / [f     next / previous function start
  ]c / [c     next / previous class
  ]a / [a     next / previous parameter
  ]f then ]F often = start vs end variants (config-dependent)

Bonus: flash.nvim's S enters treesitter mode — labels appear on nodes,
pick one to select it. Three different routes to 'select by syntax'."

  quiz "Key to EXPAND selection by syntax node?" "ctrl-space|<C-space>" ""
  quiz "Key to SHRINK that selection?" "backspace|<bs>|ctrl-space-back" "<bs> in the default incremental setup"
  quiz "Jump to the next function start?" "]f" ""
  quiz "Jump to the previous class?" "[c" ""
  quiz "flash key that selects treesitter nodes?" "S" ""

  guided "Real nvim: cursor on a variable inside a function. Press
<C-space> repeatedly — watch the selection grow node by node out to the
whole function. <bs> shrinks it. Then ]f / [f to hop between functions."
}

# ------------------------------------------------------------------ queries
lesson_queries() {
  brief "QUERIES are how you ASK the tree for things — the language
behind highlighting, textobjects, folds, everything. Syntax (it's
S-expressions):

  (identifier)                 match any identifier node
  (function_declaration)       match a function declaration
  (function_declaration
    name: (identifier) @name)  match a fn decl, CAPTURE its name child
  \"function\" @keyword          an anonymous node (the literal keyword)

  @name is a CAPTURE — a label you pull results out by.

PREDICATES filter matches (the #... forms):
  (#eq? @name \"foo\")           capture text must equal foo
  (#match? @name \"^_\")         capture text matches a regex
  (#any-of? @name \"a\" \"b\")     one of a set

Queries live in queries/<lang>/*.scm on the runtimepath:
  highlights.scm  textobjects.scm  folds.scm  injections.scm  indents.scm
Files in after/queries/<lang>/ EXTEND the built-in ones."

  quiz "A labeled result you extract from a query is a?" "capture|@capture" "written @name"
  quiz "Node types in a query are written inside?" "parentheses|()|(parens)" ""
  quiz "Predicate: capture text equals a string?" "#eq?|eq?" ""
  quiz "Predicate: capture matches a regex?" "#match?|match?" ""
  quiz "Query file for syntax highlighting?" "highlights.scm|highlights" ""
  quiz "Folder whose queries EXTEND the built-ins?" "after/queries|after queries|after" ""
}

# ------------------------------------------------------------------ writing
lesson_writing() {
  brief "Time to write a query and run it. The API:

  local q = vim.treesitter.query.parse('lua', '(identifier) @id')
  for id, node in q:iter_captures(root, source) do
    local name = q.captures[id]                       -- the capture name
    local text = vim.treesitter.get_node_text(node, source)
  end

You'll write a query that captures the NAME of every top-level function.
Recall the shape from the inspect lesson:
  (function_declaration name: (identifier) @name)

Create query.scm with that query. The check parses a sample with two
functions (alpha, beta) and prints the captured names — it must print
alpha,beta. (Experiment live with :EditQuery in real nvim too.)"

  quiz "Function to compile a query string?" "vim.treesitter.query.parse|query.parse" ""
  quiz "Iterate the captures of a query over a node?" "iter_captures|q:iter_captures" ""
  quiz "Get the source text of a node?" "vim.treesitter.get_node_text|get_node_text" ""
  quiz "Query capturing a function declaration's name?" \
    "(function_declaration name: (identifier) @name)|function_declaration name: (identifier) @name" \
    "the field 'name:' targets the right child"

  shell_task \
"Create query.scm containing a Lua treesitter query that captures the
name identifier of each function declaration as @name. The check runs
it against: alpha() and beta() — it must capture alpha,beta." \
'cat > .run.lua <<"LUA"
local src = "local function alpha() end\nfunction beta() end\n"
local q = table.concat(vim.fn.readfile("query.scm"), "\n")
local query = vim.treesitter.query.parse("lua", q)
local root = vim.treesitter.get_string_parser(src, "lua"):parse()[1]:root()
local names = {}
for id, node in query:iter_captures(root, src) do
  if query.captures[id] == "name" then names[#names+1] = vim.treesitter.get_node_text(node, src) end
end
print(table.concat(names, ","))
LUA
nvim -l .run.lua 2>&1 | tr -d "\r" | grep -qx "alpha,beta"' \
    "query.scm: (function_declaration name: (identifier) @name)"
}

# --------------------------------------------------------------- injections
lesson_injections() {
  brief "Three advanced query files round out mastery:

  injections.scm  embed one language INSIDE another — SQL inside a Lua
                  string, Lua inside a markdown code fence, bash in a
                  heredoc. The injected region gets parsed + highlighted
                  by the OTHER grammar. Capture a region as
                  @injection.content with (#set! injection.language \"sql\").

  folds.scm       defines what folds (capture nodes as @fold).
  indents.scm     drives = / auto-indent.

OVERRIDING: drop a file in after/queries/<lang>/highlights.scm to ADD
to (extend) the bundled query, or queries/<lang>/highlights.scm to
REPLACE it. ';; extends' as the first line means 'inherit then add'.
This is how you fix a mis-highlight or add a custom capture without
forking the parser.

You now have the whole stack: tree -> textobjects -> queries -> your
own captures and injections."

  quiz "Query file that embeds another language?" "injections.scm|injections" ""
  quiz "Capture name for embedded code content?" "@injection.content|injection.content" ""
  quiz "Query file that defines folding?" "folds.scm|folds" ""
  quiz "Put a query here to EXTEND the bundled one?" "after/queries|after queries|after" ""
  quiz "First-line directive to inherit then add to a query?" "; extends|;; extends|extends" \
    "; extends as the top line of an after/queries file"

  guided "Real nvim: open a markdown file with a fenced code block, or a
lua file with vim.cmd[[ ... ]] — :InspectTree shows the INJECTED tree of
the inner language. :Inspect inside it shows it's highlighted by the
other grammar. That's injections.scm at work."
}

# ------------------------------------------------------------------- drills
drills() {
  add_quiz "Treesitter parses code into a?" "tree|syntax tree"
  add_quiz "Regex-based? (yes/no)" "no"
  add_quiz "Install a parser?" "TSInstall"
  add_quiz "Declarative parser list?" "ensure_installed"
  add_quiz "View the live syntax tree?" "InspectTree"
  add_quiz "Highlight groups under the cursor?" "Inspect"
  add_quiz "Meaningful nodes are called?" "named|named nodes"
  add_quiz "Keyword/punct nodes are called?" "anonymous|anonymous nodes"
  add_quiz "A labeled child (name:/body:) is a?" "field"
  add_quiz "Select a whole function?" "vaf|af|daf"
  add_quiz "Inner function body?" "if"
  add_quiz "Parameter textobject?" "aa|ia"
  add_quiz "Expand selection by node?" "ctrl-space"
  add_quiz "Next function start?" "]f"
  add_quiz "A query result label is a?" "capture"
  add_quiz "Predicate: text equals?" "#eq?"
  add_quiz "Predicate: regex match?" "#match?"
  add_quiz "Highlighting query file?" "highlights.scm|highlights"
  add_quiz "Compile a query string?" "vim.treesitter.query.parse|query.parse"
  add_quiz "Embed another language via?" "injections.scm|injections"
  add_quiz "Folder to extend bundled queries?" "after/queries|after"
}
