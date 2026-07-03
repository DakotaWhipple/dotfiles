-- The app shell: a persistent three-pane tab (problem | code / results),
-- a dashboard front door, and highlighted results that read like a real
-- console. Panels are validity-checked and rebuilt if you close them —
-- output must never vanish into a dead buffer.
local config = require("dojo-leetcode.config")

local M = {}

local ns = vim.api.nvim_create_namespace("dojo-leetcode")

-- One session at a time.
M.session = nil
M.dashboard = nil

-- ─────────────────────────────────────────────── highlights ──

local function setup_highlights()
  local links = {
    DojoPass = "DiagnosticOk",
    DojoFail = "DiagnosticError",
    DojoSlow = "DiagnosticWarn",
    DojoDim = "Comment",
    DojoTitle = "Title",
    DojoKey = "Special",
    DojoConsole = "String",
  }
  for group, link in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

-- ─────────────────────────────────────────────── buffer helpers ──

-- entries: list of { text, hl? } (or plain strings)
local function set_panel_lines(buf, entries)
  local lines = {}
  for i, e in ipairs(entries) do
    lines[i] = type(e) == "string" and e or e.text
  end
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, e in ipairs(entries) do
    if type(e) == "table" and e.hl then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { line_hl_group = e.hl })
    end
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function scratch_buf(name, filetype)
  -- A previous session's scratch buffer may still exist under this name;
  -- reuse it so nvim_buf_set_name doesn't collide.
  local existing = vim.fn.bufnr("^" .. vim.fn.fnameescape(name) .. "$")
  if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
    return existing
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  if filetype then
    vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
  end
  return buf
end

local function set_panel_win_opts(win)
  local opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    wrap = true,
    list = false,
    spell = false,
    cursorline = false,
    statuscolumn = "",
  }
  for k, v in pairs(opts) do
    vim.api.nvim_set_option_value(k, v, { win = win, scope = "local" })
  end
end

local function win_showing(tab, buf)
  if not (tab and vim.api.nvim_tabpage_is_valid(tab)) then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

local function fmt_ms(ms)
  if ms >= 1000 then
    return string.format("%.1fs", ms / 1000)
  end
  return ms .. "ms"
end

local function truncate(s, width)
  if #s <= width then
    return s
  end
  return s:sub(1, width - 1) .. "…"
end

-- ─────────────────────────────────────────────── keymaps ──

local function apply_keymaps(buf)
  local p = config.keymap_prefix
  local maps = {
    { "r", "validate", "dojo: run tests" },
    { "y", "try_prompt", "dojo: try an expression" },
    { "t", "test_add", "dojo: add a test case" },
    { "h", "hint", "dojo: hint" },
    { "n", "next", "dojo: next stage" },
    { "v", "review", "dojo: review (after the win)" },
    { "d", "menu", "dojo: dashboard" },
  }
  for _, m in ipairs(maps) do
    vim.keymap.set("n", p .. m[1], function()
      require("dojo-leetcode")[m[2]]()
    end, { buffer = buf, desc = m[3], nowait = true })
  end
end

local KEYS_LINE = function()
  local p = config.keymap_prefix
  return ("%sr run · %sy try · %st add test · %sh hint · %sn next · %sv review · %sd menu"):format(
    p, p, p, p, p, p, p
  )
end

-- ─────────────────────────────────────────────── workspace files ──

function M.workspace_file(archetype_id)
  return config.workspace_dir .. "/" .. archetype_id .. ".kt"
end

local function ensure_workspace_file(archetype)
  vim.fn.mkdir(config.workspace_dir, "p")
  local path = M.workspace_file(archetype.id)
  if vim.fn.filereadable(path) == 0 then
    local f = io.open(path, "w")
    f:write(archetype.scaffold)
    f:close()
  end
  return path
end

local function quiet_lsp_for(buf)
  if config.quiet_lsp then
    vim.diagnostic.enable(false, { bufnr = buf })
  end
end

-- ─────────────────────────────────────────────── layout ──

local function build_layout(archetype)
  setup_highlights()
  local kt_path = ensure_workspace_file(archetype)

  vim.cmd("tabedit " .. vim.fn.fnameescape(kt_path))
  local tab = vim.api.nvim_get_current_tabpage()
  local code_win = vim.api.nvim_get_current_win()
  local code_buf = vim.api.nvim_get_current_buf()
  quiet_lsp_for(code_buf)

  vim.cmd("vertical topleft 46split")
  local desc_win = vim.api.nvim_get_current_win()
  local desc_buf = scratch_buf("dojo://" .. archetype.id .. "/problem", "markdown")
  vim.api.nvim_win_set_buf(desc_win, desc_buf)
  set_panel_win_opts(desc_win)
  vim.api.nvim_set_option_value("winfixwidth", true, { win = desc_win, scope = "local" })

  vim.api.nvim_set_current_win(code_win)
  vim.cmd("belowright 14split")
  local results_win = vim.api.nvim_get_current_win()
  local results_buf = scratch_buf("dojo://" .. archetype.id .. "/results", nil)
  vim.api.nvim_win_set_buf(results_win, results_buf)
  set_panel_win_opts(results_win)
  vim.api.nvim_set_option_value("winfixheight", true, { win = results_win, scope = "local" })

  for _, b in ipairs({ desc_buf, code_buf, results_buf }) do
    apply_keymaps(b)
  end

  local prev = M.session
  M.session = {
    archetype = archetype,
    tab = tab,
    desc_buf = desc_buf,
    code_buf = code_buf,
    results_buf = results_buf,
    -- carry run state across a layout rebuild
    last_result = prev and prev.archetype.id == archetype.id and prev.last_result or nil,
    stage_started = prev and prev.archetype.id == archetype.id and prev.stage_started or nil,
  }

  vim.api.nvim_set_current_win(code_win)
end

--- True if the session exists; rebuilds any closed pane as a side effect.
function M.ensure()
  local s = M.session
  if not s then
    return false
  end
  local intact = vim.api.nvim_buf_is_valid(s.desc_buf)
    and vim.api.nvim_buf_is_valid(s.code_buf)
    and vim.api.nvim_buf_is_valid(s.results_buf)
    and win_showing(s.tab, s.desc_buf)
    and win_showing(s.tab, s.code_buf)
    and win_showing(s.tab, s.results_buf)
  if not intact then
    build_layout(s.archetype)
    M.render_description()
  end
  return true
end

function M.open(archetype)
  build_layout(archetype)
  M.mark_stage_start()
  M.render_description()
  set_panel_lines(M.session.results_buf, {
    { text = "Write your solution in the code pane, then " .. config.keymap_prefix .. "r (or :DojoValidate) to run.", hl = "DojoDim" },
    { text = "Output — test results, your printlns, timings — lands here.", hl = "DojoDim" },
  })
end

-- ─────────────────────────────────────────────── description pane ──

function M.render_description()
  if not M.session then
    return
  end
  local progression = require("dojo-leetcode.progression")
  local state = require("dojo-leetcode.state")
  local archetype = M.session.archetype
  local stage_idx = progression.current_stage_index(archetype)
  local complete = progression.is_complete(archetype)
  local stage = archetype.stages[stage_idx]

  local e = {}
  local function add(text, hl)
    table.insert(e, hl and { text = text, hl = hl } or text)
  end

  add(archetype.title, "DojoTitle")
  if complete then
    add("COMPLETE — every stage beaten. " .. config.keymap_prefix .. "v for the review.", "DojoPass")
  else
    add(("stage %d of %d"):format(stage_idx, #archetype.stages), "DojoDim")
  end
  add("")
  for _, l in ipairs(vim.split(stage.constraint, "\n")) do
    add(l)
  end
  add("")
  add("tests", "DojoTitle")
  for _, t in ipairs(stage.tests) do
    add("  • " .. truncate(t.call, 42), "DojoDim")
    if t.budget_ms then
      add("      within " .. fmt_ms(t.budget_ms), "DojoSlow")
    end
  end
  local customs = state.load_custom_tests(archetype.id)
  for _, t in ipairs(customs) do
    add("  • " .. truncate(t.call, 38) .. "  (yours)", "DojoKey")
  end
  if stage_idx > 1 then
    add(("  plus every test from stages 1–%d (regression)"):format(stage_idx - 1), "DojoDim")
  end
  add("")
  add("keys", "DojoTitle")
  add(KEYS_LINE(), "DojoKey")
  add("")
  add("file", "DojoTitle")
  add(vim.fn.fnamemodify(M.workspace_file(archetype.id), ":~"), "DojoDim")

  set_panel_lines(M.session.desc_buf, e)
end

-- ─────────────────────────────────────────────── results pane ──

function M.results(entries)
  if not M.ensure() then
    return
  end
  set_panel_lines(M.session.results_buf, entries)
end

function M.mark_stage_start()
  if M.session then
    M.session.stage_started = vim.uv.hrtime()
  end
end

function M.clear_result()
  if M.session then
    M.session.last_result = nil
  end
end

function M.current_code_source()
  if not M.session then
    return nil
  end
  return table.concat(vim.api.nvim_buf_get_lines(M.session.code_buf, 0, -1, false), "\n")
end

local STATUS_ICON = {
  PASS = { "✓", "DojoPass" },
  FAIL = { "✗", "DojoFail" },
  ERROR = { "✗", "DojoFail" },
  SLOW = { "⚠", "DojoSlow" },
}

function M.show_result(result)
  if not M.ensure() then
    return
  end
  M.session.last_result = result

  local e = {}
  local function add(text, hl)
    table.insert(e, hl and { text = text, hl = hl } or text)
  end

  if result.compile_error then
    add("COMPILE / RUN ERROR", "DojoFail")
    for _, l in ipairs(vim.split(result.compile_error, "\n")) do
      if l ~= "" then
        add("  " .. l)
      end
    end
    M.results(e)
    return
  end

  local pass_count = 0
  for i = 1, #result.tests do
    local r = result.results[i]
    if r and r.status == "PASS" then
      pass_count = pass_count + 1
    end
  end

  local header = ("%d/%d passed"):format(pass_count, #result.tests)
  if result.elapsed_ms then
    header = header .. ("   (compile+run %s)"):format(fmt_ms(result.elapsed_ms))
  end
  add(header, result.ok and "DojoPass" or "DojoTitle")
  add("")

  for i, test in ipairs(result.tests) do
    local r = result.results[i] or { status = "ERROR", detail = "no result — did an earlier test crash?" }
    local icon = STATUS_ICON[r.status] or { "?", "DojoDim" }
    local line = (" %s %-7s %s"):format(icon[1], tostring(test.stage or ""), truncate(test.call, 64))
    if r.actual then
      line = line .. "  → " .. truncate(r.actual, 40)
    end
    if r.ms then
      line = line .. "  " .. fmt_ms(r.ms)
    end
    add(line, icon[2])
    if r.status ~= "PASS" and r.detail and r.detail ~= "" then
      add("      " .. r.detail, "DojoDim")
    end
  end

  if result.console and #result.console > 0 then
    add("")
    add("console", "DojoTitle")
    for _, l in ipairs(result.console) do
      add("  │ " .. l, "DojoConsole")
    end
  end

  if result.ok then
    local state = require("dojo-leetcode.state")
    local elapsed_ms = math.floor((vim.uv.hrtime() - (M.session.stage_started or vim.uv.hrtime())) / 1e6)
    local prev_pb = state.record_solve(M.session.archetype.id, result.stage_idx, elapsed_ms)
    local pb_note = not prev_pb and "first clear"
      or elapsed_ms < prev_pb and ("new PB! (was " .. fmt_ms(prev_pb) .. ")")
      or ("PB " .. fmt_ms(prev_pb))
    add("")
    add((" stage solved in %s — %s"):format(fmt_ms(elapsed_ms), pb_note), "DojoPass")
    add(" " .. config.keymap_prefix .. "n for the next stage.", "DojoKey")
  end

  M.results(e)
end

function M.show_try_result(expr, out)
  local e = {
    { text = "try  " .. expr, hl = "DojoTitle" },
    "",
  }
  if out.console then
    for _, l in ipairs(out.console) do
      table.insert(e, { text = "  │ " .. l, hl = "DojoConsole" })
    end
  end
  if out.value then
    table.insert(e, { text = "  → " .. out.value, hl = "DojoPass" })
  elseif out.error then
    for _, l in ipairs(vim.split(out.error, "\n")) do
      table.insert(e, { text = "  ✗ " .. l, hl = "DojoFail" })
    end
  end
  if out.elapsed_ms then
    table.insert(e, { text = ("  (compile+run %s)"):format(fmt_ms(out.elapsed_ms)), hl = "DojoDim" })
  end
  M.results(e)
end

function M.show_hint(hint)
  local e = { { text = "hint", hl = "DojoTitle" }, "" }
  for _, l in ipairs(vim.split(hint, "\n")) do
    table.insert(e, "  " .. l)
  end
  M.results(e)
end

function M.show_busy(what)
  M.results({ { text = what .. " — kotlinc takes a few seconds…", hl = "DojoDim" } })
end

-- ─────────────────────────────────────────────── review ──

function M.show_review(archetype)
  local lines = { "# " .. archetype.title .. " — review", "" }
  for i, a in ipairs(archetype.approaches or {}) do
    vim.list_extend(lines, { "## " .. i .. ". " .. a.name, "**" .. a.complexity .. "**", "" })
    vim.list_extend(lines, vim.split(a.note, "\n"))
    vim.list_extend(lines, { "", "```kotlin" })
    vim.list_extend(lines, vim.split(vim.trim(a.code), "\n"))
    vim.list_extend(lines, { "```", "" })
  end
  if #lines == 2 then
    table.insert(lines, "_No editorial written for this archetype yet._")
  end

  vim.cmd("botright vsplit")
  local buf = scratch_buf("dojo://" .. archetype.id .. "/review", "markdown")
  vim.api.nvim_win_set_buf(0, buf)
  set_panel_win_opts(0)
  vim.api.nvim_set_option_value("conceallevel", 2, { win = 0, scope = "local" })
  set_panel_lines(buf, lines)
  apply_keymaps(buf)
end

-- ─────────────────────────────────────────────── dashboard ──

function M.open_dashboard()
  setup_highlights()
  local progression = require("dojo-leetcode.progression")
  local state = require("dojo-leetcode.state")

  local e = {}
  local line_to_id = {}
  local function add(text, hl)
    table.insert(e, hl and { text = text, hl = hl } or text)
  end

  add("⛩  dojo-leetcode", "DojoTitle")
  add("")
  local kotlinc_ok = vim.fn.executable("kotlinc") == 1
  add(
    kotlinc_ok and "  kotlinc ✓" or "  kotlinc MISSING — brew install kotlin",
    kotlinc_ok and "DojoPass" or "DojoFail"
  )
  add("  solutions save to " .. vim.fn.fnamemodify(config.workspace_dir, ":~"), "DojoDim")
  add("")
  add("problems", "DojoTitle")

  local progress = state.load()
  local any_started = false
  for _, id in ipairs(progression.list_archetype_ids()) do
    local a = progression.load_archetype(id)
    if a then
      local cur = state.get_stage(id)
      local status, hl
      if cur > #a.stages then
        status, hl = "done ✓", "DojoPass"
      elseif progress[id] then
        status, hl = ("stage %d/%d"):format(cur, #a.stages), "DojoSlow"
        any_started = true
      else
        status, hl = "new", "DojoDim"
      end
      add(("  %-42s %s"):format(truncate(a.title, 40), status), hl)
      line_to_id[#e] = id
    end
  end

  add("")
  add("keys", "DojoTitle")
  add("  <CR> open problem under cursor · q close", "DojoKey")
  add("  " .. KEYS_LINE(), "DojoKey")
  if not any_started then
    add("")
    add("first time?", "DojoTitle")
    add("  1. <CR> on Two Sum — problem left, your code right, results below")
    add("  2. write Kotlin in solve(), save-optional, hit " .. config.keymap_prefix .. "r")
    add("  3. stuck? " .. config.keymap_prefix .. "h. curious? " .. config.keymap_prefix .. "y runs any expression against your code")
    add("  4. :checkhealth dojo-leetcode if anything seems broken")
  end

  vim.cmd("tabnew")
  local buf = scratch_buf("dojo://dashboard", nil)
  vim.api.nvim_win_set_buf(0, buf)
  set_panel_win_opts(0)
  set_panel_lines(buf, e)
  apply_keymaps(buf)

  M.dashboard = { buf = buf, line_to_id = line_to_id }
  vim.keymap.set("n", "<CR>", function()
    local id = M.dashboard.line_to_id[vim.api.nvim_win_get_cursor(0)[1]]
    if id then
      require("dojo-leetcode").start(id)
    end
  end, { buffer = buf, nowait = true, desc = "dojo: open problem" })
  vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = buf, nowait = true, desc = "dojo: close" })

  -- park the cursor on the first problem row
  for row in pairs(line_to_id) do
    vim.api.nvim_win_set_cursor(0, { row, 2 })
    break
  end
end

return M
