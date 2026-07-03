return {
  dir = "~/tempo.nvim",
  name = "tempo.nvim",
  cmd = {
    "Tempo",
    "TempoStart",
    "TempoValidate",
    "TempoCases",
    "TempoNext",
    "TempoHint",
    "TempoReset",
    "TempoReview",
    "TempoTry",
    "TempoTestAdd",
    "TempoTests",
  },
  -- Load on workspace .kt files too, so :TempoValidate works right after
  -- reopening nvim on a solution file (session gets adopted automatically).
  event = { "BufReadPre " .. vim.fn.expand("~") .. "/.local/state/tempo/workspace/*.kt" },
  config = function()
    require("tempo").setup({})
  end,
}
