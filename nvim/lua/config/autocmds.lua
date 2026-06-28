-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Expose a known server socket so `theme set <vibe>` can recolor running
-- instances live (it sends `:colorscheme` over RPC to every socket here).
local sock_dir = vim.fn.stdpath("cache") .. "/theme-servers"
vim.fn.mkdir(sock_dir, "p")
local sock = sock_dir .. "/" .. vim.fn.getpid() .. ".sock"
pcall(vim.fn.serverstart, sock)
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    pcall(os.remove, sock)
  end,
})
