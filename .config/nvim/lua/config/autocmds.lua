-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- catppuccin's snacks integration never defines SnacksInput* groups (the
-- rename/move file box, since LazyVim uses Snacks.input for vim.ui.input),
-- leaving them empty/unstyled. custom_highlights and a config() override on
-- the plugin spec BOTH silently never ran — LazyVim applies the designated
-- colorscheme plugin's setup through its own bootstrap path, bypassing a
-- plugin's own config() function entirely for that one plugin. Verified via
-- lazy.core.config's resolved plugin table plus a direct execution probe.
-- A plain autocmd here has no such lifecycle to get bypassed.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin",
  callback = function()
    local ok, palettes = pcall(require, "catppuccin.palettes")
    if not ok then
      return
    end
    local colors = palettes.get_palette("mocha")
    vim.api.nvim_set_hl(0, "SnacksInputNormal", { bg = colors.surface0, fg = colors.text })
    vim.api.nvim_set_hl(0, "SnacksInputBorder", { bg = colors.surface0, fg = colors.blue })
    vim.api.nvim_set_hl(0, "SnacksInputTitle", { bg = colors.surface0, fg = colors.blue, bold = true })
  end,
})
