# .dotfiles

Personal terminal setup for macOS — one script from zero to fully configured shell.

## Table of contents

- [Install](#install)
- [What install.sh does](#what-installsh-does)
- [Structure](#structure)
- [Installed tools](#installed-tools)
- [Day-to-day](#day-to-day)

---

## Install

> macOS only. Requires an internet connection.

```bash
# 1. clone the repo into ~/.dotfiles
git clone https://github.com/val3ntin-ch/.dotfiles ~/.dotfiles

# 2. run the bootstrap — installs all tools, stows dotfiles, sets zsh as default shell
~/.dotfiles/install.sh
```

Open a new terminal when done. Zsh is the default shell with all plugins active.

> **Machine-specific config** (API keys, SDK paths, local tools) goes in  
> `~/.config/zsh/.zshrc.local` — created manually per machine, never committed.

---

## What install.sh does

| Step | Action |
|---|---|
| 0 | Install Xcode CLI tools (C compiler for nvim-treesitter) |
| 1 | Install Homebrew (skip if already installed) |
| 2 | Install all CLI tools via `brew install` |
| 3 | Install Yazi + preview dependencies via `brew install` |
| 4 | Install Sesh via custom tap |
| 5 | Install Ghostty + Nerd Fonts via `brew install --cask` |
| 6 | Stow dotfiles to `$HOME` via GNU Stow + create runtime dirs |
| 7 | Set zsh as default shell via `chsh` |
| 8 | Install fish plugins via Fisher |
| 9 | Bootstrap tmux plugins via TPM |
| 10 | Install Node LTS via fnm + global npm packages (neovim, tree-sitter-cli) |

**After install — one-time per machine:**

```bash
# set git identity
cat > ~/.config/git/config.local << EOF
[user]
    name  = Your Name
    email = you@example.com
EOF

# open nvim — plugins install automatically (~2-5 min first launch)
nvim
```

---

## Structure

```
~/.dotfiles/
├── install.sh              macOS bootstrap script
├── .zshenv                 sets ZDOTDIR=~/.config/zsh (only file at $HOME)
└── .config/
    ├── fish/               Fish shell — conf.d, functions, abbreviations
    ├── git/                Git — shared config + delta diff + global ignore
    ├── zsh/                Zsh — antidote plugins, aliases, completions
    ├── nvim/               Neovim — LazyVim + React/TS/Tailwind/ESLint/Prettier
    ├── tmux/               Tmux — keybindings, plugins, status bar
    ├── lazygit/            Lazygit — Catppuccin Mocha theme + delta pager
    ├── ghostty/            Ghostty terminal config
    ├── starship/           Starship prompt (shared by fish + zsh)
    ├── sesh/               Sesh session manager
    └── yazi/               Yazi file manager + previews
```

---

## Installed tools

### Terminal & shells

| Tool | Purpose |
|---|---|
| [Ghostty](https://ghostty.org) | Terminal emulator |
| [fish](https://fishshell.com) | Interactive shell |
| [zsh](https://zsh.sourceforge.io) | Default shell |
| [starship](https://starship.rs) | Prompt — shared by fish and zsh |

### Core CLI

| Tool | Purpose |
|---|---|
| [neovim](https://neovim.io) | Editor |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [yazi](https://yazi-rs.github.io) | File manager with image preview |
| [git](https://git-scm.com) | Version control |
| [gh](https://cli.github.com) | GitHub CLI |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI |
| [git-delta](https://dandavison.github.io/delta) | Diff pager |
| [sesh](https://github.com/joshmedeski/sesh) | Tmux session manager |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` with frecency |
| [eza](https://eza.rocks) | Modern `ls` |
| [bat](https://github.com/sharkdp/bat) | Modern `cat` with syntax highlighting |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast `grep` |
| [fd](https://github.com/sharkdp/fd) | Fast `find` |
| [vivid](https://github.com/sharkdp/vivid) | `LS_COLORS` theme generator |
| [ouch](https://github.com/ouch-org/ouch) | Compress and decompress archives |
| [jq](https://jqlang.github.io/jq) | JSON processor |
| [watchman](https://facebook.github.io/watchman) | File watcher (React Native) |
| [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) | Markdown linter |

### Yazi preview dependencies

| Tool | Enables |
|---|---|
| ffmpeg-full | Video thumbnails |
| imagemagick-full | Image preview |
| poppler | PDF preview |
| resvg | SVG preview |
| sevenzip | Archive contents |

### Language runtimes & managers

| Tool | Purpose |
|---|---|
| [node](https://nodejs.org) | System Node (for Mason/tooling) |
| [fnm](https://github.com/Schniz/fnm) | Node version manager (installs LTS on setup) |
| [pnpm](https://pnpm.io) | Node package manager |
| [go](https://go.dev) | Go toolchain |
| [pyenv](https://github.com/pyenv/pyenv) | Python version manager |
| [rbenv](https://github.com/rbenv/rbenv) | Ruby version manager |

### Neovim — via [LazyVim](https://lazyvim.org) + [Mason](https://github.com/mason-org/mason.nvim)

| Layer | Tool | Purpose |
|---|---|---|
| LSP | vtsls | TypeScript / JavaScript |
| LSP | eslint-lsp | ESLint linting |
| LSP | tailwindcss-ls | Tailwind class completions |
| LSP | cssls | CSS / SCSS |
| LSP | html | HTML |
| LSP | emmet_ls | Emmet snippets |
| LSP | graphql-ls | GraphQL |
| LSP | jsonls | JSON + schema validation |
| LSP | yamlls | YAML (Docker Compose, CI configs) |
| LSP | dockerls | Dockerfile |
| LSP | marksman | Markdown |
| Formatter | prettier | JS/TS/CSS/HTML/JSON/YAML |
| Formatter | stylua | Lua |
| Formatter | shfmt | Shell |
| Tests | neotest + neotest-jest | Run Jest tests inline |
| Theme | Catppuccin Mocha | Matches ghostty, tmux, yazi |

### Fish plugins — via [Fisher](https://github.com/jorgebucaran/fisher)

| Plugin | Purpose |
|---|---|
| [jorgebucaran/fisher](https://github.com/jorgebucaran/fisher) | Plugin manager |
| [kidonng/zoxide.fish](https://github.com/kidonng/zoxide.fish) | Zoxide integration |
| [patrickf1/fzf.fish](https://github.com/PatrickF1/fzf.fish) | fzf key bindings |
| [jhillyerd/plugin-git](https://github.com/jhillyerd/plugin-git) | Git abbreviations |
| [catppuccin/fish](https://github.com/catppuccin/fish) | Catppuccin Mocha theme |
| [budimanjojo/tmux.fish](https://github.com/budimanjojo/tmux.fish) | Tmux integration |

### Zsh plugins — via [antidote](https://getantidote.github.io)

| Plugin | Purpose |
|---|---|
| zsh-users/zsh-completions | Completion definitions for 100+ tools |
| zdharma-continuum/fast-syntax-highlighting | As-you-type syntax coloring |
| zsh-users/zsh-autosuggestions | Fish-style ghost text from history |
| zsh-users/zsh-history-substring-search | `↑/↓` searches history by substring |
| Aloxaf/fzf-tab | Replaces completion menu with fzf |
| jeffreytse/zsh-vi-mode | Full vi keybindings + text objects |
| hlissner/zsh-autopair | Auto-close brackets and quotes |
| kutsan/zsh-system-clipboard | Vi-mode yank/paste ↔ system clipboard |
| MichaelAquilina/zsh-you-should-use | Reminds you to use defined aliases |
| mollifier/cd-gitroot | `cdg` — jump to git repo root |

Native (no plugin needed):
- **dotenv** — auto-source `.env` on `cd` with per-directory allow/deny list
- **magic-enter** — empty `Enter` → `eza -la` or `git status`
- **colored man pages** — via `MANPAGER=bat`

### Tmux plugins — via [TPM](https://github.com/tmux-plugins/tpm)

| Plugin | Purpose |
|---|---|
| tmux-plugins/tmux-sensible | Sane defaults |
| tmux-plugins/tmux-resurrect | Save and restore sessions across reboots |
| tmux-plugins/tmux-continuum | Auto-save sessions every 15 min |
| tmux-plugins/tmux-yank | System clipboard integration |
| christoomey/vim-tmux-navigator | Seamless pane/split navigation with Neovim |
| sainnhe/tmux-fzf | fzf-powered tmux actions |
| wfxr/tmux-fzf-url | Open URLs from pane output with fzf |
| catppuccin/tmux | Catppuccin Mocha theme |
| tmux-plugins/tmux-cpu | CPU usage in status bar |
| tmux-plugins/tmux-battery | Battery percentage in status bar |

### Fonts

| Font | Purpose |
|---|---|
| JetBrains Mono Nerd Font | Primary monospace font |
| Symbols Only Nerd Font | Nerd Font icon fallback |

---

## Day-to-day

**Re-stow after adding or moving dotfiles:**

```bash
cd ~/.dotfiles && stow --target="$HOME" --restow .
```

**Yazi plugins** — not installed by `install.sh`, run once manually:

```bash
ya pkg install
```

**Machine-local config** — create once per machine, never committed:

```bash
# API tokens, SDK paths, local tool config
~/.config/zsh/.zshrc.local

# git identity
~/.config/git/config.local
```
