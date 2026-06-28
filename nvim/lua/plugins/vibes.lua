-- Vibe theming: the colorscheme follows ~/.config/theme/nvim, which is
-- written by `theme set <vibe>`. Running instances are recolored live over
-- RPC (see the server-socket autocmd in config/autocmds.lua).

local function vibe_colorscheme()
  local f = io.open(vim.fs.normalize("~/.config/theme/nvim"), "r")
  if not f then
    return "catppuccin-mocha"
  end
  local name = f:read("*l")
  f:close()
  if name and #name > 0 then
    return name
  end
  return "catppuccin-mocha"
end

return {
  -- cozy keeps catppuccin; every other vibe uses a generated rice-<vibe>
  -- colorscheme built by `theme-palette` from the same palette as the
  -- terminal/borders/wallpaper (see ~/dotfiles/nvim/rice/colors/)
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "mocha" } }, -- cozy
  {
    name = "rice-themes",
    dir = vim.fs.normalize("~/dotfiles/nvim/rice"),
    lazy = false,
    priority = 1000,
  },

  { "LazyVim/LazyVim", opts = { colorscheme = vibe_colorscheme() } },

  -- seamless ctrl-hjkl between kitty splits and nvim splits
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false, -- must run at startup to flag the kitty window as nvim
    opts = { at_edge = "stop" },
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to above split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      { "<C-A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<C-A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<C-A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<C-A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
    },
  },
}
