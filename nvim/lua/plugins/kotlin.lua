return {
  -- Disable the community kotlin_language_server so it doesn't conflict with the JetBrains one
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = false,
      },
    },
  },

  -- Setup the official JetBrains Kotlin LSP using the community integration plugin
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("kotlin").setup({})
    end,
  },
}
