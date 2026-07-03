local M = {}

local config = require("dojo-leetcode.config")
local progression = require("dojo-leetcode.progression")
local ui = require("dojo-leetcode.ui")

-- If there's no session but the current buffer is a workspace .kt file
-- (say, after restarting nvim), adopt it instead of demanding :Dojo first.
local function adopt_session_from_buffer()
  local bufname = vim.api.nvim_buf_get_name(0)
  local ws = config.workspace_dir
  if bufname:sub(1, #ws) ~= ws then
    return false
  end
  local id = vim.fn.fnamemodify(bufname, ":t:r")
  local archetype = progression.load_archetype(id)
  if not archetype then
    return false
  end
  ui.open(archetype)
  return true
end

local function current_archetype()
  if not ui.session and not adopt_session_from_buffer() then
    vim.notify("dojo-leetcode: no active problem — :Dojo opens the menu", vim.log.levels.WARN)
    return nil
  end
  return ui.session.archetype
end

function M.menu()
  ui.open_dashboard()
end

function M.start(archetype_id)
  local archetype, err = progression.load_archetype(archetype_id)
  if not archetype then
    local ids = table.concat(progression.list_archetype_ids(), ", ")
    vim.notify(
      "dojo-leetcode: unknown problem '" .. tostring(archetype_id) .. "' (" .. tostring(err) .. "). Available: " .. ids,
      vim.log.levels.ERROR
    )
    return
  end
  ui.open(archetype)
end

function M.validate()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  ui.show_busy("compiling + running")
  progression.validate(archetype, ui.current_code_source(), function(result)
    ui.show_result(result)
    ui.render_description()
  end)
end

--- Run an arbitrary expression against the current buffer's code.
--- The REPL half of the UX: see real output, poke at edge cases, no judge.
function M.try(expr)
  local archetype = current_archetype()
  if not archetype then
    return
  end
  local judge = require("dojo-leetcode.judge")
  ui.show_busy("trying " .. expr)
  judge.try(ui.current_code_source(), expr, function(out)
    ui.show_try_result(expr, out)
  end)
end

function M.try_prompt()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  vim.ui.input({ prompt = "try: ", default = "solve(" }, function(expr)
    if expr and expr ~= "" then
      M.try(expr)
    end
  end)
end

--- Add a personal test case: runs with every validate from now on.
function M.test_add()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  vim.ui.input({ prompt = "test call: ", default = "solve(" }, function(call)
    if not call or call == "" then
      return
    end
    vim.ui.input({ prompt = "expected (kotlin expr): " }, function(expected)
      if not expected or expected == "" then
        return
      end
      require("dojo-leetcode.state").add_custom_test(archetype.id, call, expected)
      ui.render_description()
      ui.results({
        { text = "added test: " .. call .. " == " .. expected, hl = "DojoPass" },
        { text = "it now runs on every " .. config.keymap_prefix .. "r · edit/remove via :DojoTests", hl = "DojoDim" },
      })
    end)
  end)
end

--- Open the custom-tests JSON for direct editing.
function M.tests_edit()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  vim.cmd("split " .. vim.fn.fnameescape(require("dojo-leetcode.state").custom_tests_path(archetype.id)))
end

-- Only advances if the most recent validate for THIS stage passed —
-- the gate is having actually solved it, not asking to move on.
function M.next()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  if progression.is_complete(archetype) then
    ui.results({ { text = "already complete — " .. config.keymap_prefix .. "v for the review", hl = "DojoPass" } })
    return
  end

  local stage_idx = progression.current_stage_index(archetype)
  local last = ui.session.last_result
  if not last or last.stage_idx ~= stage_idx or not last.ok then
    ui.results({
      { text = "pass every test first (" .. config.keymap_prefix .. "r), then advance", hl = "DojoSlow" },
    })
    return
  end

  ui.clear_result()
  local advanced = progression.advance(archetype)
  ui.render_description()
  if advanced then
    ui.mark_stage_start()
    ui.results({
      { text = ("stage %d — the constraint just changed. read the left pane."):format(
        progression.current_stage_index(archetype)
      ), hl = "DojoTitle" },
    })
  else
    ui.results({
      { text = "COMPLETE — every stage beaten, regression included.", hl = "DojoPass" },
      { text = config.keymap_prefix .. "v — see every approach and what each one trades away.", hl = "DojoKey" },
    })
  end
end

-- The editorial is earned: locked until the archetype is complete, because
-- reading the answers first would delete the discovery this exists for.
function M.review(force)
  local archetype = current_archetype()
  if not archetype then
    return
  end
  if not force and not progression.is_complete(archetype) then
    ui.results({
      { text = "review unlocks when every stage is beaten (:DojoReview! to spoil yourself)", hl = "DojoSlow" },
    })
    return
  end
  ui.show_review(archetype)
end

function M.hint()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  ui.show_hint(progression.current_stage(archetype).hint or "No hint for this stage.")
end

function M.reset()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  progression.reset(archetype)
  ui.clear_result()
  ui.mark_stage_start()
  ui.render_description()
  ui.results({ { text = "progress reset — back to stage 1", hl = "DojoTitle" } })
end

local initialized = false

function M.setup(opts)
  if initialized then
    return
  end
  initialized = true
  config.apply(opts)

  -- Workspace .kt buffers: LSP completion/hover stay, diagnostics hush.
  if config.quiet_lsp then
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      pattern = config.workspace_dir .. "/*.kt",
      callback = function(ev)
        vim.diagnostic.enable(false, { bufnr = ev.buf })
      end,
    })
  end

  local function cmd(name, fn, o)
    vim.api.nvim_create_user_command(name, fn, o or {})
  end

  local complete_ids = function()
    return progression.list_archetype_ids()
  end

  -- :Dojo → dashboard; :Dojo two_sum → straight in.
  cmd("Dojo", function(c)
    if c.args ~= "" then
      M.start(c.args)
    else
      M.menu()
    end
  end, { nargs = "?", complete = complete_ids })
  cmd("DojoLeetcodeStart", function(c)
    M.start(c.args ~= "" and c.args or "two_sum")
  end, { nargs = "?", complete = complete_ids })

  cmd("DojoValidate", M.validate)
  cmd("DojoNext", M.next)
  cmd("DojoHint", M.hint)
  cmd("DojoReset", M.reset)
  cmd("DojoReview", function(c)
    M.review(c.bang)
  end, { bang = true })
  cmd("DojoTry", function(c)
    if c.args ~= "" then
      M.try(c.args)
    else
      M.try_prompt()
    end
  end, { nargs = "*" })
  cmd("DojoTestAdd", M.test_add)
  cmd("DojoTests", M.tests_edit)
end

return M
