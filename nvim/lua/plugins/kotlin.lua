return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "kotlin-lsp" })
    end,
  },

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
