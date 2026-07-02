local M = {}

local ns = vim.api.nvim_create_namespace("dojo-leetcode")

-- One session at a time: the currently open archetype + its two buffers.
M.session = nil

local function workspace_path(archetype_id)
  local dir = vim.fn.expand("~/.local/state/dojo-leetcode/workspace")
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. archetype_id .. ".kt"
end

local function ensure_workspace_file(archetype)
  local path = workspace_path(archetype.id)
  if vim.fn.filereadable(path) == 0 then
    local f = io.open(path, "w")
    f:write(archetype.scaffold)
    f:close()
  end
  return path
end

local function render_info_lines(archetype, stage_idx, status_lines)
  local stage = archetype.stages[stage_idx]
  local lines = {
    archetype.title .. "  —  Stage " .. stage_idx .. "/" .. #archetype.stages,
    string.rep("─", 60),
    "",
  }
  vim.list_extend(lines, vim.split(stage.constraint, "\n"))
  vim.list_extend(lines, {
    "",
    ":DojoValidate check   ·   :DojoHint hint   ·   :DojoNext advance   ·   :DojoReset restart",
    "",
  })
  if status_lines and #status_lines > 0 then
    table.insert(lines, string.rep("─", 60))
    vim.list_extend(lines, status_lines)
  end
  return lines
end

local function set_info_buf(bufnr, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

function M.open(archetype, progression)
  local stage_idx = progression.current_stage_index(archetype)
  local kt_path = ensure_workspace_file(archetype)

  vim.cmd("tabnew")
  local info_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = info_buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = info_buf })
  vim.api.nvim_buf_set_name(info_buf, "[dojo:" .. archetype.id .. "]")
  set_info_buf(info_buf, render_info_lines(archetype, stage_idx, nil))

  vim.cmd("vsplit " .. vim.fn.fnameescape(kt_path))
  local code_win = vim.api.nvim_get_current_win()
  local code_buf = vim.api.nvim_get_current_buf()

  M.session = {
    archetype = archetype,
    info_buf = info_buf,
    code_buf = code_buf,
    code_win = code_win,
  }

  vim.api.nvim_set_current_win(code_win)
end

function M.current_code_source()
  if not M.session then
    return nil
  end
  return table.concat(vim.api.nvim_buf_get_lines(M.session.code_buf, 0, -1, false), "\n")
end

function M.refresh_info(status_lines)
  if not M.session then
    return
  end
  local progression = require("dojo-leetcode.progression")
  local archetype = M.session.archetype
  local stage_idx = progression.current_stage_index(archetype)
  set_info_buf(M.session.info_buf, render_info_lines(archetype, stage_idx, status_lines))
end

local function status_line_for(test_result, test)
  local prefix = test_result.status == "PASS" and "  [PASS] " or "  [FAIL] "
  local line = prefix .. test.call
  if test_result.status ~= "PASS" then
    line = line .. "  -- " .. test_result.detail
  end
  return line, test_result.status == "PASS"
end

function M.clear_result()
  if M.session then
    M.session.last_result = nil
  end
end

function M.show_result(result)
  if not M.session then
    return
  end
  M.session.last_result = result

  if result.compile_error then
    M.refresh_info({ "COMPILE ERROR:", "", result.compile_error })
    vim.notify("dojo-leetcode: compile error", vim.log.levels.ERROR)
    return
  end

  local lines = {}
  local pass_count = 0
  for i, test in ipairs(result.tests) do
    local r = result.results[i]
    if r then
      local line, ok = status_line_for(r, test)
      table.insert(lines, "stage " .. test.stage .. line)
      if ok then
        pass_count = pass_count + 1
      end
    else
      table.insert(lines, "stage " .. test.stage .. "  [????] " .. test.call)
    end
  end
  table.insert(lines, "")
  table.insert(lines, pass_count .. "/" .. #result.tests .. " passed")
  if result.ok then
    table.insert(lines, "Stage complete — :DojoNext to continue.")
  end

  M.refresh_info(lines)
  vim.notify(
    "dojo-leetcode: " .. pass_count .. "/" .. #result.tests .. " passed",
    result.ok and vim.log.levels.INFO or vim.log.levels.WARN
  )
end

function M.show_hint(hint)
  vim.notify("dojo-leetcode hint: " .. hint, vim.log.levels.INFO)
end

return M
