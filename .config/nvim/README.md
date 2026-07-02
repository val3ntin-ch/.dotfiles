# Neovim — LazyVim

Full-featured Neovim setup built on [LazyVim](https://www.lazyvim.org). Configured for React, React Native, Next.js, TypeScript, Tailwind CSS.

---

## Table of contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Extras enabled](#extras-enabled)
4. [LSPs + formatters + linters](#lsps--formatters--linters)
5. [Keybindings](#keybindings)
6. [Managing plugins](#managing-plugins)
7. [Config structure](#config-structure)

---

## Requirements

All installed automatically by `~/.dotfiles/install.sh`:

| Requirement | Installed by |
|---|---|
| Neovim >= 0.11.2 (LuaJIT) | `brew install neovim` |
| Git >= 2.19.0 | `brew install git` |
| JetBrains Mono Nerd Font v3+ | `brew install --cask font-jetbrains-mono-nerd-font` |
| lazygit | `brew install lazygit` |
| tree-sitter-cli | `brew install tree-sitter` |
| fzf >= 0.25.1 | `brew install fzf` |
| ripgrep | `brew install ripgrep` |
| fd | `brew install fd` |
| curl | pre-installed on macOS |
| Ghostty (true color terminal) | `brew install --cask ghostty` |

---

## Installation

Handled entirely by `~/.dotfiles/install.sh`. On a new machine:

```bash
# 1. clone dotfiles + run bootstrap
git clone https://github.com/val3ntin-ch/.dotfiles ~/.dotfiles
~/.dotfiles/install.sh

# 2. open nvim — plugins install automatically on first launch (~2-5 min)
nvim

# 3. verify everything is working
# inside nvim:
:LazyHealth
```

---

## Extras enabled

Managed via `lazyvim.json`. Toggle with `:LazyExtras` inside nvim.

### Language
| Extra | Provides |
|---|---|
| `lang.typescript` + `lang.typescript.vtsls` | vtsls LSP, tsx/ts treesitter, nvim-ts-autotag |
| `lang.json` | jsonls + SchemaStore validation |
| `lang.tailwind` | tailwindcss-language-server |
| `lang.markdown` | marksman LSP, markdown preview |
| `lang.docker` | dockerls, docker-compose LSP, dockerfile treesitter |
| `lang.yaml` | yamlls + schema validation |

> CSS/HTML/GraphQL/Emmet LSPs configured manually in `lua/plugins/webdev.lua` (no `lang.css` extra — doesn't cover emmet/graphql).

### Formatting & linting
| Extra | Provides |
|---|---|
| `formatting.prettier` | prettier via conform.nvim for js/ts/jsx/tsx/json/css/html/md |
| `linting.eslint` | eslint_d via nvim-lint for js/ts/jsx/tsx |

### Coding
| Extra | Provides |
|---|---|
| `coding.yanky` | Enhanced yank/paste history |
| `editor.dial` | Increment/decrement values with `+`/`-` |
| `editor.inc-rename` | LSP rename with live preview |
| `editor.neo-tree` | File explorer sidebar (`<leader>e`) |

### Utils
| Extra | Provides |
|---|---|
| `test.core` | Test runner integration (neotest) |
| `util.dot` | Dotfile editing helpers |
| `util.mini-hipatterns` | Highlight hex colors, TODO, FIXME inline |

---

## LSPs + formatters + linters

Auto-installed by Mason on first launch.

| Tool | Type | Handles |
|---|---|---|
| vtsls | LSP | TypeScript, JavaScript, JSX, TSX |
| tailwindcss-language-server | LSP | Tailwind CSS class completions |
| cssls | LSP | CSS, SCSS, Less |
| html-lsp | LSP | HTML |
| json-lsp + SchemaStore | LSP | JSON/JSONC with schema validation |
| marksman | LSP | Markdown |
| graphql-language-service | LSP | GraphQL |
| lua-language-server | LSP | Lua (for editing nvim config) |
| prettier | Formatter | JS/TS/JSX/TSX/JSON/CSS/HTML/MD |
| eslint_d | Linter | JS/TS/JSX/TSX |
| stylua | Formatter | Lua |

---

## Keybindings

LazyVim uses `<Space>` as leader. Key prefixes:

| Prefix | Category |
|---|---|
| `<leader>f` | Find (fzf-lua) |
| `<leader>g` | Git (lazygit, hunks) |
| `<leader>c` | Code (LSP actions) |
| `<leader>l` | Lazy (plugin manager) |
| `<leader>m` | Mason |
| `<leader>x` | Diagnostics (trouble.nvim) |
| `<leader>t` | Test (neotest) |

### Code actions

| Key | Action |
|---|---|
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol (inc-rename — live preview) |
| `<leader>cf` | Format file (prettier) |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover documentation |
| `<leader>cd` | Line diagnostics |
| `]d` / `[d` | Next/prev diagnostic |

### File navigation

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>e` | File explorer (neo-tree) |

### Git

| Key | Action |
|---|---|
| `<leader>gg` | Open lazygit |
| `]h` / `[h` | Next/prev hunk |
| `<leader>gh` | Preview hunk |

---

## Managing plugins

```bash
# inside nvim:
:Lazy          # plugin manager — update, install, clean
:LazyExtras    # toggle extras on/off
:Mason         # manage LSPs, formatters, linters
:MasonUpdate   # update all Mason packages
:LazyHealth    # verify everything is working
```

---

## Config structure

```
~/.config/nvim/                 (symlink → ~/.dotfiles/.config/nvim/)
├── init.lua                    entry point
├── lazyvim.json                active extras (managed by :LazyExtras)
├── lazy-lock.json              pinned plugin versions (committed)
├── stylua.toml                 Lua formatter config
├── .neoconf.json               LSP config for editing nvim config itself
└── lua/
    ├── config/
    │   ├── lazy.lua            lazy.nvim bootstrap
    │   ├── options.lua         custom vim options
    │   ├── keymaps.lua         custom keymaps
    │   └── autocmds.lua        custom autocommands
    └── plugins/
        └── webdev.lua          Catppuccin + JSX autotag + HTML/GraphQL LSP
```

### Adding a plugin

Create any `.lua` file in `lua/plugins/` — lazy.nvim auto-loads it:

```lua
return {
  "author/plugin-name",
  opts = {},
}
```

### Adding a keymap

```lua
-- lua/config/keymaps.lua
vim.keymap.set("n", "<leader>xx", function()
  -- action
end, { desc = "Description" })
```
