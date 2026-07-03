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

  -- kotlin LSP: optional (completion/hover). The judge never needs it —
  -- compile errors and leetcode-level diagnostics come from kotlinc runs.
  local kotlin_clients = vim.tbl_filter(function(c)
    return c.name:lower():find("kotlin") ~= nil
  end, vim.lsp.get_clients())
  if #kotlin_clients > 0 then
    local c = kotlin_clients[1]
    health.ok(("kotlin LSP running: %s (root: %s)"):format(c.name, c.root_dir or "none — single-file mode"))
    local attached = false
    for b in pairs(c.attached_buffers or {}) do
      if vim.api.nvim_buf_get_name(b):sub(1, #config.workspace_dir) == config.workspace_dir then
        attached = true
        break
      end
    end
    if attached then
      health.ok("attached to a dojo workspace buffer")
    else
      health.info("not attached to any dojo workspace buffer right now")
    end
    if not c.root_dir then
      health.info(
        "no project root → JetBrains kotlin-lsp analyzes the file standalone; "
          .. "expect completion/hover but few or no LSP diagnostics. "
          .. "The judge's diagnostics (compile errors, off-by-one, edge cases) don't depend on it."
      )
    end
  else
    health.info(
      "no kotlin LSP client active right now (it attaches ~15s after a .kt buffer opens; JVM startup). "
        .. "LSP is optional — the judge compiles with kotlinc regardless."
    )
  end
  if config.quiet_lsp then
    health.warn("quiet_lsp=true: LSP diagnostics are muted in dojo workspace buffers")
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
