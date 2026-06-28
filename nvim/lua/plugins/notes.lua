-- Notes: zk-powered vault at ~/notes (see ~/dotfiles/zk/config.toml).
-- [[wiki links]] complete via the zk LSP; pickers reuse fzf-lua, which is
-- already vibe-themed. Shell side lives in ~/dotfiles/bin (note, jot, notes).

local function zk(cmd, opts)
  return function()
    require("zk.commands").get(cmd)(opts)
  end
end

return {
  {
    "zk-org/zk-nvim",
    ft = "markdown",
    cmd = { "ZkNotes", "ZkNew", "ZkBacklinks", "ZkLinks", "ZkTags", "ZkNewFromTitleSelection", "ZkNewFromContentSelection" },
    keys = {
      { "<leader>nn", function()
        vim.ui.input({ prompt = "Title: " }, function(title)
          if title and #title > 0 then
            require("zk.commands").get("ZkNew")({ title = title })
          end
        end)
      end, desc = "New note" },
      { "<leader>nd", zk("ZkNew", { dir = "journal" }), desc = "Daily note" },
      { "<leader>nf", zk("ZkNotes", { sort = { "modified" } }), desc = "Find notes" },
      { "<leader>ns", function()
        vim.ui.input({ prompt = "Search: " }, function(q)
          if q and #q > 0 then
            require("zk.commands").get("ZkNotes")({ sort = { "modified" }, match = { q } })
          end
        end)
      end, desc = "Search notes (full-text)" },
      { "<leader>nb", zk("ZkBacklinks"), desc = "Backlinks" },
      { "<leader>nl", zk("ZkLinks"), desc = "Outbound links" },
      { "<leader>nt", zk("ZkTags"), desc = "Tags" },
      { "<leader>nn", ":'<,'>ZkNewFromTitleSelection<CR>", mode = "v", desc = "New note (selection as title)" },
      { "<leader>nc", ":'<,'>ZkNewFromContentSelection { title = vim.fn.input('Title: ') }<CR>", mode = "v", desc = "New note (selection as content)" },
    },
    config = function()
      require("zk").setup({
        picker = "fzf_lua",
        lsp = {
          auto_attach = { enabled = true, filetypes = { "markdown" } },
        },
      })

      -- <leader>n is the notes prefix; move LazyVim's notification history off it
      pcall(vim.keymap.del, "n", "<leader>n")

      -- in-vault markdown: enter follows [[links]], K previews the target
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("notes_vault_keys", { clear = true }),
        pattern = {
          (vim.env.ZK_NOTEBOOK_DIR or vim.fs.normalize("~/notes")) .. "/*.md",
          (vim.env.ZK_NOTEBOOK_DIR or vim.fs.normalize("~/notes")) .. "/**/*.md",
        },
        callback = function(ev)
          vim.keymap.set("n", "<CR>", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Follow link" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Preview link" })
        end,
      })
    end,
  },

  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>n", group = "notes" } } },
  },
}
