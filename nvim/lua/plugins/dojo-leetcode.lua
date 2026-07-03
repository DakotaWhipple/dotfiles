return {
  dir = vim.fn.stdpath("config") .. "/dojo-leetcode.nvim",
  name = "dojo-leetcode.nvim",
  cmd = {
    "Dojo",
    "DojoLeetcodeStart",
    "DojoValidate",
    "DojoCases",
    "DojoNext",
    "DojoHint",
    "DojoReset",
    "DojoReview",
    "DojoTry",
    "DojoTestAdd",
    "DojoTests",
  },
  -- Load on workspace .kt files too, so :DojoValidate works right after
  -- reopening nvim on a solution file (session gets adopted automatically).
  event = { "BufReadPre " .. vim.fn.expand("~") .. "/.local/state/dojo-leetcode/workspace/*.kt" },
  config = function()
    require("dojo-leetcode").setup({})
  end,
}
