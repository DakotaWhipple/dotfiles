local M = {}

local function state_dir()
  return vim.fn.expand("~/.local/state/dojo-leetcode")
end

local function progress_path()
  return state_dir() .. "/progress.json"
end

function M.load()
  vim.fn.mkdir(state_dir(), "p")
  local path = progress_path()
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  if content == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

function M.save(data)
  vim.fn.mkdir(state_dir(), "p")
  local f = io.open(progress_path(), "w")
  if not f then
    return
  end
  f:write(vim.json.encode(data))
  f:close()
end

-- Current stage number for an archetype (1-indexed, defaults to 1).
function M.get_stage(archetype_id)
  local data = M.load()
  return (data[archetype_id] and data[archetype_id].stage) or 1
end

function M.set_stage(archetype_id, stage)
  local data = M.load()
  data[archetype_id] = data[archetype_id] or {}
  data[archetype_id].stage = stage
  data[archetype_id].updated_at = os.time()
  M.save(data)
end

-- Records a validation attempt outcome so future variation selection /
-- mastery signal (Phase 2) has real usage data to work from.
function M.record_attempt(archetype_id, stage, passed)
  local data = M.load()
  data[archetype_id] = data[archetype_id] or {}
  local entry = data[archetype_id]
  entry.attempts = (entry.attempts or 0) + 1
  if passed then
    entry.passes = (entry.passes or 0) + 1
  end
  entry.last_stage_attempted = stage
  entry.updated_at = os.time()
  M.save(data)
end

-- Records a stage solve time; keeps the per-stage personal best.
-- Returns the previous PB in ms (nil on first solve) so the UI can
-- show "new PB" vs "PB stands".
function M.record_solve(archetype_id, stage, ms)
  local data = M.load()
  data[archetype_id] = data[archetype_id] or {}
  local entry = data[archetype_id]
  entry.pb = entry.pb or {}
  local key = tostring(stage)
  local prev = entry.pb[key]
  if not prev or ms < prev then
    entry.pb[key] = ms
  end
  entry.updated_at = os.time()
  M.save(data)
  return prev
end

return M
