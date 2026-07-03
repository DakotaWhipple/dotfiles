-- :checkhealth dojo-leetcode
local M = {}

function M.check()
  local health = vim.health
  local config = require("dojo-leetcode.config")
  health.start("dojo-leetcode")

  -- kotlinc: the judge. Non-negotiable.
  if vim.fn.executable("kotlinc") == 1 then
    local version = vim.fn.systemlist("kotlinc -version 2>&1")[1] or "unknown"
    health.ok("kotlinc found: " .. version)
  else
    health.error("kotlinc not found", { "brew install kotlin" })
  end

  -- workspace dir: where solutions live.
  local ws = config.workspace_dir
  if vim.fn.isdirectory(ws) == 1 or vim.fn.mkdir(ws, "p") == 1 then
    health.ok("workspace writable: " .. ws)
  else
    health.error("cannot create workspace dir: " .. ws)
  end

  -- kotlin LSP: optional (completion/hover). The judge never needs it.
  local kotlin_clients = vim.tbl_filter(function(c)
    return c.name:lower():find("kotlin") ~= nil
  end, vim.lsp.get_clients())
  if #kotlin_clients > 0 then
    health.ok("kotlin LSP running: " .. kotlin_clients[1].name)
  else
    health.info(
      "no kotlin LSP client active right now (it attaches when a .kt buffer opens). "
        .. "LSP is optional — the judge compiles with kotlinc regardless."
    )
  end
  if config.quiet_lsp then
    health.info("quiet_lsp=true: LSP diagnostics are muted in dojo workspace buffers (judge is the referee)")
  end

  -- archetypes load cleanly
  local progression = require("dojo-leetcode.progression")
  local ids = progression.list_archetype_ids()
  local broken = {}
  for _, id in ipairs(ids) do
    local a = select(1, progression.load_archetype(id))
    if not a then
      table.insert(broken, id)
    end
  end
  if #broken == 0 then
    health.ok(#ids .. " problems load cleanly: " .. table.concat(ids, ", "))
  else
    health.error("problems failed to load: " .. table.concat(broken, ", "))
  end
end

return M
