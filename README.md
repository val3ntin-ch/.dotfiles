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

# 2. run the bootstrap — installs all tools, stows dotfiles, sets fish as default shell
~/.dotfiles/install.sh
```

Open a new terminal when done. Fish is the default shell; zsh is fully configured too.

> **Machine-specific config** (API keys, SDK paths, local tools) goes in  
> `~/.config/zsh/.zshrc.local` — created manually per machine, never committed.

---

## What install.sh does

| Step | Action |
|---|---|
| 0 | Install or update Xcode CLI tools via `softwareupdate` (C compiler for nvim-treesitter; Homebrew needs them current); accepts the Xcode license if full Xcode is installed |
| 1 | Install Homebrew (skip if already installed) |
| 2 | Install all CLI tools via `brew install` |
| 3 | Install Yazi + preview dependencies via `brew install` |
| 4 | Install herdr, Claude Code, Codex, OpenCode, Conductor; remove stale non-brew copies in `~/.local/bin` |
| 5 | Install Ghostty + Nerd Fonts via `brew install --cask` |
| 6 | Stow dotfiles to `$HOME` via GNU Stow + create runtime dirs. Pre-existing real files that would conflict (e.g. app-created `~/.config/git/ignore`) are backed up as `*.bak` automatically |
| 7 | Set fish as default shell via `chsh` (`LOGIN_SHELL=zsh ./install.sh` for zsh; skipped if already set) |
| 8 | Install fish plugins via Fisher |
| 9 | Install herdr agent-state hooks for claude, codex, opencode |
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
├── installAi.sh            agent plugins/skills + agent configs (web)
├── installAiMobile.sh      installAi.sh + React Native skills
├── agents/                 Claude/Codex/OpenCode base configs (merged, not stowed)
├── .zshenv                 sets ZDOTDIR=~/.config/zsh (only file at $HOME)
└── .config/
    ├── fish/               Fish shell — conf.d, functions, abbreviations
    ├── git/                Git — shared config + delta diff + global ignore
    ├── zsh/                Zsh — antidote plugins, aliases, completions
    ├── nvim/               Neovim — LazyVim + React/TS/Tailwind/ESLint/Prettier
    ├── herdr/              Herdr — agent multiplexer (replaces tmux)
    ├── lazygit/            Lazygit — Catppuccin Mocha theme + delta pager
    ├── ghostty/            Ghostty terminal config
    ├── starship/           Starship prompt (shared by fish + zsh)
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
| [herdr](https://herdr.dev) | Terminal multiplexer for AI agents |
| [yazi](https://yazi-rs.github.io) | File manager with image preview |
| [git](https://git-scm.com) | Version control |
| [gh](https://cli.github.com) | GitHub CLI |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI |
| [git-delta](https://dandavison.github.io/delta) | Diff pager |
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
| Theme | Catppuccin Mocha | Matches ghostty, herdr, yazi |

### Fish plugins — via [Fisher](https://github.com/jorgebucaran/fisher)

| Plugin | Purpose |
|---|---|
| [jorgebucaran/fisher](https://github.com/jorgebucaran/fisher) | Plugin manager |
| [kidonng/zoxide.fish](https://github.com/kidonng/zoxide.fish) | Zoxide integration |
| [patrickf1/fzf.fish](https://github.com/PatrickF1/fzf.fish) | fzf key bindings |
| [jhillyerd/plugin-git](https://github.com/jhillyerd/plugin-git) | Git abbreviations |
| [catppuccin/fish](https://github.com/catppuccin/fish) | Catppuccin Mocha theme |

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

### AI agents

| Tool | Purpose |
|---|---|
| [Claude Code](https://claude.com/claude-code) | Anthropic coding agent (native installer, auto-updates) |
| [Codex](https://github.com/openai/codex) | OpenAI coding agent (cask) |
| [OpenCode](https://opencode.ai) | Open-source coding agent (`anomalyco/tap`) |
| [Conductor](https://conductor.build) | Mac app — parallel Claude/Codex agents in worktrees |

Each CLI agent gets herdr's integration hook (`herdr integration install …`),
so the herdr sidebar shows whether an agent is working, waiting or done.

### Fonts

| Font | Purpose |
|---|---|
| JetBrains Mono Nerd Font | Primary monospace font |
| Symbols Only Nerd Font | Nerd Font icon fallback |

---

## Day-to-day

**Update a machine to the latest dotfiles:**

```bash
cd ~/.dotfiles && git pull
exec zsh          # or: exec fish — restart shell to pick up changes
```

Configs are symlinks, so `git pull` updates them in place — no re-stow needed
unless files were added/moved. Herdr: `Ctrl+t r` reloads the config.

**Re-stow after adding or moving dotfiles:**

```bash
cd ~/.dotfiles && stow --target="$HOME" --restow .
```

**Stow refuses with "cannot stow ... over existing target"** — a real file sits
where a symlink must go (`install.sh` handles this automatically; manual fix):

```bash
cd ~/.dotfiles
stow --adopt .    # moves the machine's files into the repo
git diff          # inspect what the machine version had
git restore .     # keep the repo version (or commit files you want to keep)
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

---

## Herdr + Neovim workflow

Prefix is `Ctrl+t` (same as the old tmux setup).

| Keys | Action |
|---|---|
| `hdev [-a codex\|opencode] [dir\|zoxide-query]` | Workspace for a project: nvim 70% + agent 30% (default agent: claude). Reuses an open workspace with the same name |
| `Ctrl+h/j/k/l` in nvim | Move between nvim splits, then into the neighbouring herdr pane |
| `prefix h/j/k/l` | Move between herdr panes (from a shell/agent pane) |
| `prefix g` / `prefix v` | Split side by side / stacked |
| `prefix o` | Workspace picker (was sesh) |
| `prefix shift+g` | New git worktree workspace — run a second agent on its own branch |
| `prefix alt+g` / `prefix y` | lazygit / yazi popup |
| `prefix f` | Go to (was `prefix g` in herdr defaults) |
| `prefix r` | Reload config |
| `prefix ?` | All keys |

Agents running in herdr can drive it too: `herdr --skill` prints the skill
file that teaches an agent to open panes and start other agents.

---

## Privacy / telemetry

Opt-outs set by this repo. Auto-updates stay on for Claude Code.

| Where | What |
|---|---|
| `.config/zsh/.zshenv`, `.config/fish/conf.d/env.fish` | `DO_NOT_TRACK`, Claude Code `DISABLE_TELEMETRY` + `DISABLE_ERROR_REPORTING`, Vercel plugin, Caveman CLI, Next.js, Turborepo, Expo, Astro, Gatsby, Storybook, Homebrew analytics |
| `agents/claude/settings.base.json` `env` | Same Claude/plugin opt-outs for agents started outside a shell (Conductor, IDE) |
| `.config/herdr/config.toml` `[update]` | No background version/manifest checks to herdr.dev — update with `brew upgrade herdr` |
| `agents/codex/config.base.toml`, `installAi.sh` | Codex `[analytics]` and `[feedback]` disabled |
| `agents/opencode/opencode.json` | `"share": "disabled"` — no session upload links |

Your prompts and code still go to the model provider; these switches only cut
the extra usage tracking.

---

## Migrating an existing machine from tmux

```bash
cd ~/.dotfiles && git pull
./install.sh                         # installs herdr/agents, restows, removes tmux symlinks
./installAi.sh                       # merges agent configs, telemetry off
brew uninstall tmux sesh             # optional, no longer used
fish -c 'fisher update'              # drops tmux.fish
nvim --headless "+Lazy! clean" +qa   # drops vim-tmux-navigator
```

