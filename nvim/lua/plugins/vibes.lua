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
}
