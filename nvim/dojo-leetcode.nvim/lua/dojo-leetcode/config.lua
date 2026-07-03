-- Plugin configuration. Standalone module (no requires) so ui/init/state
-- can all read it without circular imports.
local M = {
  -- Where your solution .kt files live. Real files on disk — LSP attaches,
  -- you can open them outside the dojo, they survive everything.
  workspace_dir = vim.fn.expand("~/.local/state/dojo-leetcode/workspace"),

  -- Mute LSP diagnostics in workspace buffers. Off by default: seeing
  -- kotlin-lsp's squiggles alongside the judge's leetcode-level diagnostics
  -- is the point. Flip on if a projectless .kt makes your LSP too noisy.
  quiet_lsp = false,

  -- Buffer-local keymap prefix inside dojo panes. Leader-based so it shows
  -- up in the which-key popup as a "dojo" group instead of shadowing ","
  -- (which LazyVim/vim already use).
  keymap_prefix = "<leader>o",
}

-- Human-readable form of a key: "<leader>or" reads as "␣or" in panes.
function M.key(suffix)
  return (M.keymap_prefix:gsub("<[Ll]eader>", "␣")) .. (suffix or "")
end

function M.apply(opts)
  for k, v in pairs(opts or {}) do
    if k == "workspace_dir" then
      v = vim.fn.expand(v)
    end
    M[k] = v
  end
end

return M
