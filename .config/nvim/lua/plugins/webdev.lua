return {
  -- disable latex rendering (not used, silences render-markdown + snacks warnings)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = { latex = { enabled = false } },
  },

  -- disable snacks auto-generating a lazygit theme — use our ~/.config/lazygit/config.yml
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = { configure = false },
    },
  },

  -- Catppuccin Mocha — matches ghostty, tmux, fish, yazi
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mini = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        -- Snacks renders the file-move/rename input box and other floating
        -- prompts (vim.ui.input, notifications, etc). This themes Snacks'
        -- dashboard/notifier/general windows, but NOT the input box
        -- specifically — catppuccin's own snacks integration never defines
        -- SnacksInput* groups at all (confirmed by reading its source).
        -- Fixed in config/autocmds.lua — see the comment there for why it's
        -- not handled here via custom_highlights/config().
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
      -- off by default: neovim core has an unfixed crash where a stale
      -- inlay-hint column (from a semantic-tokens refresh racing a buffer
      -- edit) throws "Invalid 'col': out of range" (nvim/neovim#39772),
      -- reproduced on stable 0.12.5. Toggle on with <leader>uh when wanted.
      inlay_hints = { enabled = false },
    },
  },

  -- seamless navigation between tmux panes and nvim splits (Ctrl+h/j/k/l)
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft", "TmuxNavigateDown",
      "TmuxNavigateUp", "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },

  -- auto-close and auto-rename JSX/HTML tags
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },

  -- extra treesitter parsers (docker handled by lang.docker extra)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "css",
        "scss",
        "graphql",
        "html",
      })
    end,
  },

  -- css + html + graphql + emmet LSPs
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {},
        html = {},
        graphql = {},
        -- js/ts/jsx/tsx removed: emmet treats nearly any keystroke as a
        -- possible abbreviation, flooding every JS/TS completion with tags.
        emmet_ls = {
          filetypes = { "html", "css", "scss" },
        },
      },
    },
  },

  -- friendly-snippets registers JS/TS snippets under "javascript"/"typescript"
  -- only — without this, jsx/tsx get zero snippet completions since blink.cmp
  -- doesn't know javascriptreact/typescriptreact should inherit them.
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        providers = {
          snippets = {
            opts = {
              extended_filetypes = {
                javascriptreact = { "javascript" },
                typescriptreact = { "typescript" },
              },
            },
          },
        },
      },
    },
  },

  -- Jest adapter for neotest (test.core extra provides the framework)
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-jest" },
    opts = {
      adapters = {
        ["neotest-jest"] = (function()
          -- monorepo package root (packages/<name>/) for the current file,
          -- or nil outside that layout. cwd() MUST use this too — npx jest
          -- run from the monorepo root instead of the package dir throws
          -- "cannot read package.json" whenever root has none of its own.
          local function package_root(file)
            if string.find(file, "/packages/") then
              return string.match(file, "(.-/[^/]+/)src")
            end
            return nil
          end
          return {
            jestCommand = "npx jest",
            jestConfigFile = function()
              local root = package_root(vim.fn.expand("%:p"))
              return (root or (vim.fn.getcwd() .. "/")) .. "jest.config.ts"
            end,
            env = { CI = true },
            cwd = function()
              local root = package_root(vim.fn.expand("%:p"))
              return root or vim.fn.getcwd()
            end,
          }
        end)(),
      },
    },
  },
}
