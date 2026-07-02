local state = require("dojo-leetcode.state")
local judge = require("dojo-leetcode.judge")

local M = {}

local archetypes_cache = {}

function M.load_archetype(id)
  if archetypes_cache[id] then
    return archetypes_cache[id]
  end
  local ok, archetype = pcall(require, "dojo-leetcode.archetypes." .. id)
  if not ok then
    return nil, archetype
  end
  archetypes_cache[id] = archetype
  return archetype
end

function M.list_archetype_ids()
  local dir = debug.getinfo(1, "S").source:match("@?(.*/)") .. "archetypes"
  local ids = {}
  for name, ftype in vim.fs.dir(dir) do
    if ftype == "file" and name:match("%.lua$") then
      table.insert(ids, (name:gsub("%.lua$", "")))
    end
  end
  table.sort(ids)
  return ids
end

function M.is_complete(archetype)
  return state.get_stage(archetype.id) > #archetype.stages
end

function M.current_stage_index(archetype)
  local stage = state.get_stage(archetype.id)
  if stage > #archetype.stages then
    stage = #archetype.stages
  end
  return stage
end

function M.current_stage(archetype)
  return archetype.stages[M.current_stage_index(archetype)]
end

-- Flattened, ordered tests from stage 1 through `upto` (inclusive). This is
-- what gives regression enforcement for free: once you've advanced to stage
-- N, every future submission is checked against all N stages' tests, not
-- just the latest one.
local function flatten_tests(archetype, upto)
  local tests = {}
  for stage_idx = 1, upto do
    for _, t in ipairs(archetype.stages[stage_idx].tests) do
      table.insert(tests, vim.tbl_extend("force", { stage = stage_idx }, t))
    end
  end
  return tests
end

function M.validate(archetype, user_source, on_done)
  local stage_idx = M.current_stage_index(archetype)
  local tests = flatten_tests(archetype, stage_idx)
  judge.run(user_source, tests, function(result)
    result.tests = tests
    result.stage_idx = stage_idx
    if result.results then
      state.record_attempt(archetype.id, stage_idx, result.ok)
    end
    on_done(result)
  end)
end

-- Returns false (does nothing) once already complete.
function M.advance(archetype)
  local stage_idx = M.current_stage_index(archetype)
  if stage_idx >= #archetype.stages then
    state.set_stage(archetype.id, #archetype.stages + 1)
    return false
  end
  state.set_stage(archetype.id, stage_idx + 1)
  return true
end

function M.reset(archetype)
  state.set_stage(archetype.id, 1)
end

return M
