-- vim.lsp.inlay_hint has an unfixed core crash (nvim/neovim#39772): its
-- decoration provider is registered unconditionally the moment ANYTHING
-- references the module — even just reading .is_enabled(), which LazyVim's
-- own <leader>uh keymap does eagerly at startup to build its label. That
-- alone arms the crash for the whole session regardless of opts.inlay_hints
-- or whether hints are ever actually turned on. Stub it before lazy.nvim (or
-- anything else) can require() the real module.
package.loaded["vim.lsp.inlay_hint"] = {
  enable = function() end,
  is_enabled = function()
    return false
  end,
}

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
