-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+h/j/k/l: move between nvim splits, then fall through to the
-- neighbouring herdr pane at the edge (replaces vim-tmux-navigator).
-- Outside herdr this is plain LazyVim split navigation.
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  vim.keymap.set("n", "<C-" .. key .. ">", function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. key)
    if vim.env.HERDR_ENV == "1" and win == vim.api.nvim_get_current_win() then
      vim.system({ "herdr", "pane", "focus", "--current", "--direction", dir })
    end
  end, { desc = "Go to " .. dir .. " window/pane" })
end
