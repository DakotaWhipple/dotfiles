return {
  dir = vim.fn.stdpath("config") .. "/dojo-leetcode.nvim",
  name = "dojo-leetcode.nvim",
  cmd = { "DojoLeetcodeStart", "DojoValidate", "DojoNext", "DojoHint", "DojoReset", "DojoReview" },
  config = function()
    require("dojo-leetcode").setup({})
  end,
}
