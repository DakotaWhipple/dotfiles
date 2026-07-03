-- Plugin configuration. Standalone module (no requires) so ui/init/state
-- can all read it without circular imports.
local M = {
  -- Where your solution .kt files live. Real files on disk — LSP attaches,
  -- you can open them outside the dojo, they survive everything.
  workspace_dir = vim.fn.expand("~/.local/state/dojo-leetcode/workspace"),

  -- Silence LSP diagnostics in workspace buffers. A lone .kt with no gradle
  -- project makes kotlin-lsp cry about things the judge doesn't care about;
  -- completion and hover keep working either way. The judge is the referee.
  quiet_lsp = true,

  -- Buffer-local keymap prefix inside dojo panes (",r" run, ",h" hint, ...).
  keymap_prefix = ",",
}

function M.apply(opts)
  for k, v in pairs(opts or {}) do
    if k == "workspace_dir" then
      v = vim.fn.expand(v)
    end
    M[k] = v
  end
end

return M
