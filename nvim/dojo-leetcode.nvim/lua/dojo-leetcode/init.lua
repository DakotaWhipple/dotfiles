local M = {}

local progression = require("dojo-leetcode.progression")
local ui = require("dojo-leetcode.ui")

local function current_archetype()
  if not ui.session then
    vim.notify("dojo-leetcode: no active session — run :DojoLeetcodeStart [archetype]", vim.log.levels.WARN)
    return nil
  end
  return ui.session.archetype
end

function M.start(archetype_id)
  archetype_id = archetype_id or "two_sum"
  local archetype, err = progression.load_archetype(archetype_id)
  if not archetype then
    local ids = table.concat(progression.list_archetype_ids(), ", ")
    vim.notify(
      "dojo-leetcode: unknown archetype '" .. archetype_id .. "' (" .. tostring(err) .. "). Available: " .. ids,
      vim.log.levels.ERROR
    )
    return
  end
  if progression.is_complete(archetype) then
    vim.notify("dojo-leetcode: '" .. archetype_id .. "' already complete — :DojoReset to redo it.", vim.log.levels.INFO)
  end
  ui.open(archetype, progression)
end

function M.validate()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  local source = ui.current_code_source()
  vim.notify("dojo-leetcode: compiling + running...", vim.log.levels.INFO)
  progression.validate(archetype, source, function(result)
    ui.show_result(result)
  end)
end

-- Only advances if the most recent :DojoValidate for THIS stage passed —
-- mirrors "the interviewer only lets you move on once you've actually
-- solved it," not just "you asked to move on."
function M.next()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  if progression.is_complete(archetype) then
    vim.notify("dojo-leetcode: already complete.", vim.log.levels.INFO)
    return
  end

  local stage_idx = progression.current_stage_index(archetype)
  local last = ui.session.last_result
  if not last or last.stage_idx ~= stage_idx or not last.ok then
    vim.notify("dojo-leetcode: run :DojoValidate and pass every test before advancing.", vim.log.levels.WARN)
    return
  end

  ui.clear_result()
  local advanced = progression.advance(archetype)
  if advanced then
    ui.refresh_info(nil)
    ui.mark_stage_start()
    vim.notify("dojo-leetcode: advanced to stage " .. progression.current_stage_index(archetype), vim.log.levels.INFO)
  else
    ui.refresh_info({ "Archetype complete — every stage passed, including regression.", "", ":DojoReview to see every approach and what each one trades away." })
    vim.notify("dojo-leetcode: archetype complete! :DojoReview unlocked", vim.log.levels.INFO)
  end
end

-- The editorial is earned: locked until the archetype is complete, because
-- reading the answers first would delete the discovery this exists for.
-- :DojoReview! spoils on purpose.
function M.review(force)
  local archetype = current_archetype()
  if not archetype then
    return
  end
  if not force and not progression.is_complete(archetype) then
    vim.notify(
      "dojo-leetcode: review unlocks when every stage is beaten (:DojoReview! to spoil yourself)",
      vim.log.levels.WARN
    )
    return
  end
  ui.show_review(archetype)
end

function M.hint()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  local stage = progression.current_stage(archetype)
  ui.show_hint(stage.hint or "No hint for this stage.")
end

function M.reset()
  local archetype = current_archetype()
  if not archetype then
    return
  end
  progression.reset(archetype)
  ui.clear_result()
  ui.refresh_info(nil)
  vim.notify("dojo-leetcode: progress reset for '" .. archetype.id .. "'", vim.log.levels.INFO)
end

local commands_registered = false

function M.setup(_opts)
  if commands_registered then
    return
  end
  commands_registered = true

  vim.api.nvim_create_user_command("DojoLeetcodeStart", function(cmd_opts)
    M.start(cmd_opts.args ~= "" and cmd_opts.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return progression.list_archetype_ids()
    end,
  })
  vim.api.nvim_create_user_command("DojoValidate", M.validate, {})
  vim.api.nvim_create_user_command("DojoNext", M.next, {})
  vim.api.nvim_create_user_command("DojoHint", M.hint, {})
  vim.api.nvim_create_user_command("DojoReset", M.reset, {})
  vim.api.nvim_create_user_command("DojoReview", function(cmd_opts)
    M.review(cmd_opts.bang)
  end, { bang = true })
end

return M
