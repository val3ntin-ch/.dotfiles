return {
  -- prettierd (persistent daemon) instead of prettier (spins up a fresh
  -- process per file) — formatting.prettier extra defaults to plain prettier.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        css = { "prettierd" },
        scss = { "prettierd" },
        html = { "prettierd" },
        markdown = { "prettierd" },
        yaml = { "prettierd" },
        graphql = { "prettierd" },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "prettierd" })
    end,
  },
}
