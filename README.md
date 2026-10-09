# .dotfiles

Personal terminal setup for macOS and Linux — one script from zero to fully configured shell.

## Table of contents

- [Install](#install)
- [What install.sh does](#what-installsh-does)
- [Linux](#linux)
- [Structure](#structure)
- [Installed tools](#installed-tools)
- [Day-to-day](#day-to-day)

---

## Install

> macOS: `install.sh`. Linux: `installLinux.sh` (see [Linux](#linux)).
> Requires an internet connection.

```bash
# 1. clone the repo into ~/.dotfiles
git clone https://github.com/val3ntin-ch/.dotfiles ~/.dotfiles

# 2. run the bootstrap — installs all tools, stows dotfiles, sets zsh as default shell
~/.dotfiles/install.sh
```

Open a new terminal when done. Zsh is the default shell; fish is fully configured too.

> **Machine-specific config** (API keys, SDK paths, local tools) goes in
> `~/.config/fish/config-local.fish` (fish) or `~/.config/zsh/.zshrc.local`
> (zsh) — created manually per machine, gitignored, never committed.

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
| 7 | Set zsh as default shell via `chsh` (`LOGIN_SHELL=fish ./install.sh` for fish; skipped if already set) |
| 8 | Install fish plugins via Fisher |
| 9 | Install herdr agent-state hooks for claude, codex, opencode |
| 10 | Install Node LTS via fnm + global npm packages (neovim, tree-sitter-cli) |
| 11 | Install/upgrade Yazi plugins (`ya pkg upgrade`) |

Rerunning is safe: most installed brew packages are left as they are, but
neovim and codex are upgraded on purpose, and fish plugins, yazi plugins, npm
globals and the Xcode CLI tools are updated when newer versions exist. `chsh`
and the Xcode license only prompt when something changes. Then run `./installAi.sh` (or
`./installAiMobile.sh`) for agent plugins, skills and agent configs.

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

## Linux

```bash
git clone https://github.com/val3ntin-ch/.dotfiles ~/.dotfiles
~/.dotfiles/installLinux.sh
~/.dotfiles/installAi.sh        # same AI script as macOS
```

Works on any distro family with **apt** (Debian, Ubuntu, Mint, Pop!_OS),
**dnf** (Fedora, RHEL, Alma, Rocky), or **pacman** (Arch, Manjaro, EndeavourOS), on x86_64 and aarch64. CI installs it on Ubuntu
24.04, Fedora and Arch on every PR.

How it gets each tool:

1. **Native packages first** (apt/dnf/pacman) — names are mapped per
   distro; a name the distro doesn't have is skipped, not fatal.
2. **Upstream fallback** for anything missing or too old, into `~/.local/bin`:
   GitHub releases (lazygit, eza, delta, vivid, ouch, yazi, gh, zoxide, fzf,
   resvg), neovim's release tarball when the distro's nvim is older than
   0.11.2, fzf when older than 0.48 (`fzf --fish`), and the official installers
   for starship, fnm, herdr, Claude Code and OpenCode. pyenv/rbenv are cloned.
3. **npm (via fnm's Node LTS):** codex, pnpm, yarn, markdownlint-cli2,
   neovim, tree-sitter-cli.
4. **Desktop only** (auto-detected, or `DESKTOP=1`/`0`): Ghostty from the
   official repos where it exists (Arch; elsewhere a link to
   ghostty.org's install docs) and JetBrains Mono + Symbols Nerd Fonts into
   `~/.local/share/fonts`.
5. **Same shared steps as macOS** (`lib/install-common.sh`): stow, login
   shell (`LOGIN_SHELL=zsh|fish|none`, default zsh), fish plugins, herdr agent hooks, yazi
   plugins.

**Sources — official and public only:**

| Kind | Where from |
|---|---|
| Distro packages | the distro's own official repos (no PPAs, COPRs, AUR or snaps) |
| GitHub releases | the project's own upstream repo, **sha256-verified** against the digest GitHub publishes for each asset (mismatch or no published digest = refused): junegunn/fzf, jesseduffield/lazygit, eza-community/eza, dandavison/delta, sharkdp/vivid, ouch-org/ouch, sxyazi/yazi, cli/cli, ajeetdsouza/zoxide, linebender/resvg, neovim/neovim, ryanoasis/nerd-fonts |
| Official install scripts | starship.rs, fnm.vercel.app, herdr.dev, claude.ai, opencode.ai (HTTPS, each project's documented installer) |
| Git clones | pyenv/pyenv, rbenv/rbenv, rbenv/ruby-build |
| npm registry | @openai/codex, pnpm, yarn, markdownlint-cli2, neovim, tree-sitter-cli |

Ghostty is installed only where an official distro repo has it (Arch);
elsewhere the script points to ghostty.org's install docs.

Not on Linux: Conductor (macOS app), Homebrew. Debian/Ubuntu's `batcat` and
`fdfind` are linked as `bat` and `fd`.

---

## Structure

```
~/.dotfiles/
├── install.sh              macOS bootstrap script
├── installLinux.sh         Linux bootstrap (apt/dnf/pacman)
├── doctor.sh               repair + health check, any machine
├── lib/install-common.sh   steps shared by both installers (not stowed)
├── installAi.sh            agent plugins/skills + agent configs (web) — macOS + Linux
├── installAiMobile.sh      installAi.sh + React Native skills
├── agents/                 Claude/Codex/OpenCode base configs (merged, not stowed)
├── .github/                CI workflow + check.sh (not stowed)
├── .zshenv                 sets ZDOTDIR=~/.config/zsh, sources it (only file at $HOME)
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
| [zsh](https://zsh.sourceforge.io) | Default login shell |
| [fish](https://fishshell.com) | Fully configured alternative (`LOGIN_SHELL=fish ./install.sh`) |
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
| [pnpm](https://pnpm.io) / [yarn](https://yarnpkg.com) | Node package managers |
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
| Formatter | prettierd | JS/TS/CSS/HTML/JSON/YAML/Markdown/GraphQL |
| Formatter | stylua | Lua |
| Formatter | shfmt | Shell |
| Debug | nvim-dap + js-debug-adapter | Node / Chrome debugging |
| Tests | neotest + neotest-jest | Run Jest tests inline |
| Theme | onedark (deep) | Catppuccin Mocha also installed; ghostty/herdr/yazi/fzf use Catppuccin |

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
| [squad](https://github.com/val3ntin-ch/squad) | A team of agents on one repo inside herdr: GPT-6.1 lead, Claude/Codex devs, cross-vendor reviewers, tester (`installAi.sh`) |

Claude Code's status line runs `squad statusline` (set in `agents/claude/settings.base.json`): the model plus 5-hour and 7-day plan usage bars, also recorded for squad's live strip.

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

**Something not working (hdev, shells, a tool)? Run the doctor:**

```bash
~/.dotfiles/doctor.sh           # repair, then check
~/.dotfiles/doctor.sh --check   # check only, changes nothing
```

Repairs (safe to repeat): pull the latest dotfiles (fast-forward only), remove
stale non-Homebrew copies of herdr/gh that shadow Homebrew's (macOS), re-stow,
clear zsh completion/antidote caches, sync fish plugins, restore nvim plugins
to `lazy-lock.json`, sync yazi plugins, reinstall herdr agent hooks and reload
the herdr config. Then it checks every tool, that herdr supports what `hdev`
uses, fresh login shells, `hdev` in fish and zsh, git identity and `gh` auth —
every ✗ comes with its fix. Afterwards restart open shells: `exec $SHELL`.

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

**Machine-local config** — create once per machine, never committed:

```bash
# API tokens, SDK paths, local tool config
~/.config/fish/config-local.fish
~/.config/zsh/.zshrc.local

# git identity
~/.config/git/config.local
```

---

## Herdr + Neovim workflow

Prefix is `Ctrl+t` (same as the old tmux setup).

| Keys | Action |
|---|---|
| `hdev [-o] [-n] [-a codex\|opencode] [dir\|zoxide-query]` | Open nvim (left 70%) + an agent (right 30%, default claude) for a project. What already runs is focused, not duplicated. Free panes are used first — the pane you typed `hdev` in (when it's the project's workspace), then idle shell panes — and a pane is split only when none is free. Inside a git repo it uses the repo root. Always prints what it did; herdr errors point to `doctor.sh`. `-o` agent only, `-n` forces a new workspace |
| `Ctrl+h/j/k/l` in nvim | Move between nvim splits, then into the neighbouring herdr pane |
| `prefix h/j/k/l` | Move between herdr panes (from a shell/agent pane) |
| `prefix g` / `prefix v` | Split side by side / stacked |
| `prefix o` | Workspace picker (was sesh) |
| `prefix shift+g` | New git worktree workspace — run a second agent on its own branch |
| `prefix alt+g` / `prefix y` | lazygit / yazi popup |
| `prefix f` | Go to (was `prefix g` in herdr defaults) |
| `prefix r` | Reload config |
| `prefix ?` | All keys |

**Sessions persist.** Herdr keeps a background server; closing Ghostty or
detaching (`prefix q`) leaves everything running, and `herdr` reattaches. After
a reboot or server restart herdr restores every workspace, tab and pane and
resumes each agent into its conversation (`[session] resume_agents_on_restore`).
An agent that never got a message has nothing to resume (Claude prints `No
conversation found`) and nvim isn't restored — those panes come back as plain
shells. Run `hdev` again: it focuses what's still running and
reuses those idle panes instead of adding new ones.

Agents running in herdr can drive it too: `herdr --skill` prints the skill
file that teaches an agent to open panes and start other agents.

---

## Privacy / telemetry

Opt-outs set by this repo. Auto-updates stay on for Claude Code.

| Where | What |
|---|---|
| `.config/zsh/.zshenv`, `.config/fish/conf.d/env.fish` | `DO_NOT_TRACK`, Claude Code `DISABLE_TELEMETRY` + `DISABLE_ERROR_REPORTING`, Vercel plugin, Caveman plugin, Next.js, Turborepo, Expo, Astro, Gatsby, Storybook, Homebrew analytics |
| `agents/claude/settings.base.json` `env` | Same Claude/plugin opt-outs for agents started outside a shell (Conductor, IDE) |
| `.config/herdr/config.toml` `[update]` | No background version/manifest checks to herdr.dev — update with `brew upgrade herdr` |
| `agents/codex/config.base.toml`, `installAi.sh` | Codex `[analytics]` and `[feedback]` disabled; no startup update check (`check_for_update_on_startup = false`, Homebrew updates it) |
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
