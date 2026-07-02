# ~/.config/fish — Fish Shell Configuration

## What is this directory and why does it exist?

Fish has a strict load order. Every time you open a terminal (or a new tmux
pane, or run `exec fish`) Fish loads files in this sequence:

```
~/.config/fish/config.fish          → always, every shell
~/.config/fish/conf.d/*.fish        → always, alphabetical order, before config.fish
~/.config/fish/functions/*.fish     → autoloaded on first call (lazy)
~/.config/fish/completions/*.fish   → autoloaded when tab-completing
```

**Key difference from ZSH**: Fish has no `.profile` / `.zshenv` / `.zshrc`
split. There is no "login shell vs interactive shell" distinction that matters
in practice. `conf.d/` files run for every shell. Use `status is-interactive`
to guard anything that should only run in a terminal (not scripts).

**Key difference from ZSH**: Functions are autoloaded from `functions/`.
You never need to `source` them. Drop a file `foo.fish` in `functions/` and
`foo` is available immediately in every shell, lazily loaded on first call.

---

## § 1  Plugin Manager — Fisher

```
fish_plugins   ← the plugin list (like .zsh_plugins.txt in antidote)
```

Fisher is the package manager. It reads `fish_plugins`, clones repos into
`~/.local/share/fisher`, and generates function/conf.d files.

why Fisher over others (Oh-My-Fish, etc)?
- Plugin list is a plain text file → easy to read, diff, review in git
- `fisher install`/`fisher update`/`fisher remove` — simple CLI
- Minimal: no framework magic, just sources files
- Active maintenance as of 2026

### Installed plugins

| Plugin | What it does |
|--------|-------------|
| `jorgebucaran/fisher` | Fisher itself — the package manager |
| `patrickf1/fzf.fish` | fzf key bindings: `Ctrl-R` history, `Ctrl-T` files, `Ctrl-Alt-F` dirs, `Alt-C` cd |
| `kidonng/zoxide.fish` | zoxide integration: `z`, `zi` — frecency-based directory jumping |
| `jhillyerd/plugin-git` | ~150 git abbreviations (expand in-place on Space) |
| `catppuccin/fish` | Sets `fish_color_*` variables to Catppuccin Mocha palette |
| `budimanjojo/tmux.fish` | tmux wrapper: auto-connect, TERM fixing, `ta`/`ts`/`tl`/`tksv` etc. |

---

## § 2  conf.d/ — Startup Config Files

Files load alphabetically. All run before `config.fish`.

### `conf.d/env.fish` — Environment Variables

why a separate env file?

Fish has no `.zshenv` equivalent for scripts. But `conf.d/` files run for
every shell including non-interactive ones (when called as a script interpreter).
Putting environment variables here makes them available everywhere.

| Variable | Value | Why |
|----------|-------|-----|
| `XDG_CONFIG_HOME` | `~/.config` | XDG spec — keeps home dir clean |
| `XDG_CACHE_HOME` | `~/.cache` | XDG spec |
| `XDG_DATA_HOME` | `~/.local/share` | XDG spec |
| `XDG_STATE_HOME` | `~/.local/state` | XDG spec (history files, etc.) |
| `EDITOR` | `nvim` | default editor for all tools |
| `VISUAL` | `nvim` | GUI editor fallback (same as EDITOR) |
| `PAGER` | `less` | used by git, man, etc. |
| `LESS` | `-R -F -X --use-color -j4` | `-R` = colors, `-F` = auto-exit if fits, `-X` = don't clear |
| `LESSHISTFILE` | `~/.local/state/less/history` | XDG-compliant location |
| `MANPAGER` | `sh -c 'col -bx \| bat -l man -p'` | renders man pages with bat syntax highlighting |
| `MANROFFOPT` | `-c` | fixes color rendering in man via bat |
| `BAT_THEME` | `Catppuccin Mocha` | syntax highlighting theme for bat |
| `RIPGREP_CONFIG_PATH` | `~/.config/ripgrep/config` | persistent rg flags |
| `FZF_DEFAULT_OPTS` | Catppuccin Mocha colors + bindings | see below |
| `FZF_DEFAULT_COMMAND` | `fd --type f --hidden ...` | fd instead of find (respects .gitignore) |
| `FZF_CTRL_T_COMMAND` | same as DEFAULT_COMMAND | files picker |
| `FZF_ALT_C_COMMAND` | `fd --type d ...` | dirs picker |
| `FZF_CTRL_T_OPTS` | bat preview | file content on the right |
| `FZF_ALT_C_OPTS` | eza tree preview | directory tree on the right |
| `FZF_CTRL_R_OPTS` | echo preview | history entry preview |
| `LS_COLORS` | vivid catppuccin-mocha | 200+ file type colors for ls/eza |
| `EZA_COLORS` | Catppuccin Mocha columns | user/group/size/date/git/permissions colors |
| `EZA_ICONS_AUTO` | `1` | icons without needing `--icons` flag |
| `GREP_COLORS` | Catppuccin | match/filename/line number colors |
| `GCC_COLORS` | Catppuccin | compiler error/warning/note colors |
| `LANG` / `LC_ALL` | `en_US.UTF-8` | locale |
| `GIT_EDITOR` | `nvim` | editor for commit messages, rebases |
| `GIT_PAGER` | `delta` | syntax-highlighted diffs (if delta installed) |
| `DELTA_FEATURES` | `catppuccin-mocha` | delta color theme |
| `HOMEBREW_NO_ANALYTICS` | `1` | disable brew telemetry |
| `HOMEBREW_NO_AUTO_UPDATE` | `1` | update on your terms, not brew's |

**FZF Catppuccin Mocha palette:**
```
bg+:#313244   bg:#1e1e2e    spinner:#f5e0dc  hl:#f38ba8
fg:#cdd6f4    header:#f38ba8  info:#cba6f7   pointer:#f5e0dc
marker:#a6e3a1  fg+:#cdd6f4  prompt:#cba6f7  hl+:#f38ba8
border:#6c7086  label:#cdd6f4
```

**FZF bindings added:**
- `Ctrl-/` → toggle preview panel
- `Ctrl-U` → scroll preview half-page up
- `Ctrl-D` → scroll preview half-page down

---

### `conf.d/path.fish` — PATH and Runtime Paths

fish PATH is a list variable (`$PATH`), not a colon-separated string.
`fish_add_path -g` adds to the global universal PATH, deduplicating automatically.

| Path added | Why |
|-----------|-----|
| `~/bin`, `~/.local/bin` | personal scripts |
| `/opt/homebrew/bin` (macOS) | Homebrew (Apple Silicon) |
| `/usr/local/bin` (macOS) | Homebrew (Intel) |
| `$PNPM_HOME` (`~/.local/share/pnpm`) | pnpm global binaries |
| `$BUN_INSTALL/bin` (`~/.bun/bin`) | bun runtime |
| `$GOPATH/bin` (`~/.local/share/go/bin`) | Go binaries |
| `$ANDROID_HOME/emulator` | Android emulator (React Native) |
| `$ANDROID_HOME/platform-tools` | adb (React Native) |

**Environment variables set:**

| Variable | Value |
|----------|-------|
| `PNPM_HOME` | `~/.local/share/pnpm` |
| `BUN_INSTALL` | `~/.bun` |
| `GOPATH` | `~/.local/share/go` |
| `JAVA_HOME` | Zulu JDK 17 (if installed) — React Native Android |
| `ANDROID_HOME` | `~/Library/Android/sdk` (if installed) |

---

### `conf.d/aliases.fish` — Aliases

fish `alias foo 'bar'` creates a function named `foo` that calls `bar`.
It is NOT the same as zsh's `alias`. For tool-shadowing aliases (e.g. `rg` → `rg --flags`),
always prefix with `command` inside the alias body to avoid infinite recursion.

#### Editor
| Alias | Expands to |
|-------|-----------|
| `v`, `vi`, `vim`, `nv` | `nvim` |
| `svim` | `sudo -E nvim` (preserves your nvim config) |
| `inv` | `nvim (fzf -m --preview="bat --color=always {}")` |

#### bat (replaces cat)
| Alias | Expands to |
|-------|-----------|
| `cat` | `bat --paging=never --style=plain` |
| `catn` | `bat --paging=never --style=numbers,changes` |
| `catp` | `bat --style=numbers,changes,header` (with paging) |
| `batdiff` | `bat --diff` (show only changed lines) |

#### Navigation
| Alias | Expands to |
|-------|-----------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `.....` | `cd ../../../..` |

#### ripgrep
| Alias | Expands to |
|-------|-----------|
| `rg` | `rg --color=always --smart-case` |
| `rgi` | `rg --ignore-case` |
| `rgf` | `rg --files-with-matches` |
| `rgts` | `rg --type=ts` |
| `rgjs` | `rg --type=js` |

#### fd
| Alias | Expands to |
|-------|-----------|
| `fd` | `fd --color=always` |
| `fdf` | `fd --type f` |
| `fdd` | `fd --type d` |
| `fdh` | `fd --hidden` |

#### tmux
> `ta`, `tad`, `ts`, `tl`, `tksv`, `tkss`, `tds` provided by `budimanjojo/tmux.fish`

| Alias | Expands to |
|-------|-----------|
| `t` | `tmux` |
| `tn` | `tmux new-session -s` |
| `tns` | `tmux new-session` |
| `tw` | `tmux list-windows` |
| `tk` | `tmux kill-session -t` |
| `tka` | `tmux kill-server` |
| `trn` | `tmux rename-session` |
| `tpk` | `tmux kill-pane` |
| `tsrc` | `tmux source-file ~/.config/tmux/tmux.conf` |
| `T` | `tmux new-session -A -s main` (attach to "main" or create it) |

#### pnpm
| Alias | Expands to |
|-------|-----------|
| `pn` | `pnpm` |
| `pni` | `pnpm install` |
| `pna` | `pnpm add` |
| `pnad` | `pnpm add -D` |
| `pnr` | `pnpm run` |
| `pnd` | `pnpm dev` |
| `pnb` | `pnpm build` |
| `pnt` | `pnpm test` |
| `pntw` | `pnpm test --watch` |
| `pnl` | `pnpm lint` |
| `pnlf` | `pnpm lint --fix` |
| `pntc` | `pnpm typecheck` |
| `pnx` | `pnpm dlx` (like npx) |
| `pnup` | `pnpm update --interactive --latest` |
| `pnwhy` | `pnpm why` |
| `pnclean` | `rm -rf node_modules .turbo dist && pnpm install` |

#### React Native / Expo
| Alias | Expands to |
|-------|-----------|
| `rni` | `npx react-native run-ios` |
| `rna` | `npx react-native run-android` |
| `rnios` | `npx react-native run-ios --simulator="iPhone 15 Pro"` |
| `pods` | `cd ios && bundle exec pod install && cd ..` |
| `rnclean` | watchman + rm node_modules/Pods/builds + pnpm install |
| `expo` | `npx expo` |
| `expod` | `npx expo start` |
| `expob` | `npx expo build` |
| `expodc` | `npx expo start --clear` |

#### System utilities
| Alias | Expands to |
|-------|-----------|
| `reload` | `exec fish` (fresh shell, clean state) |
| `path` | `printf "%s\n" $PATH \| nl` |
| `ports` | `lsof -i -P -n \| grep LISTEN` |
| `myip` | curl api.ipify.org |
| `df` | `df -h` |
| `du` | `du -sh` |
| `dua` | `du -sh * \| sort -h` |
| `psa` | `ps aux` |
| `psg` | `ps aux \| grep` |
| `ping` | `ping -c 5` |

#### Dotfiles
| Alias | Expands to |
|-------|-----------|
| `dot` | `cd ~/.dotfiles` |
| `frc` | `nvim ~/.config/fish/config.fish` |
| `falias` | `nvim ~/.config/fish/conf.d/aliases.fish` |
| `fenv` | `nvim ~/.config/fish/conf.d/env.fish` |
| `fpath` | `nvim ~/.config/fish/conf.d/path.fish` |
| `ffn` | `nvim ~/.config/fish/functions` |

#### Clipboard (cross-platform)
| Alias | Platform |
|-------|---------|
| `copy` / `paste` | macOS → `pbcopy` / `pbpaste` |
| `copy` / `paste` | Wayland → `wl-copy` / `wl-paste` |
| `copy` / `paste` | X11 → `xclip -selection clipboard` |

#### macOS-specific
| Alias | Expands to |
|-------|-----------|
| `o` | `open` |
| `ql` | `qlmanage -p` (QuickLook from terminal) |
| `flushdns` | `dscacheutil -flushcache && killall -HUP mDNSResponder` |
| `showfiles` | show hidden files in Finder |
| `hidefiles` | hide hidden files in Finder |
| `cleanup` | `find . -type f -name "*.DS_Store" -delete` |
| `update` | `brew update && brew upgrade && brew autoremove && brew cleanup` |
| `brewdump` | `brew bundle dump --file=~/.dotfiles/Brewfile --force` |
| `awake` | `caffeinate -d` (keep mac awake) |

---

### `conf.d/aliases.fish` — eza (tools-eza.fish)

why eza instead of ls?
eza shows icons, git status per file, column headers, human sizes, symlink targets,
color-coded permissions. Configured via `EZA_COLORS` (Catppuccin) in env.fish.

| Alias | Expands to |
|-------|-----------|
| `ls` | `eza --group-directories-first --icons` |
| `ll` | `eza -l -g --icons` |
| `la` | `eza -a --icons` |
| `lla` | `eza -la -g --icons` |
| `llt` | `eza -la -g --icons --tree --level=2` |

---

### `conf.d/git.fish` — Git Plugin Init

Initializes `jhillyerd/plugin-git` abbreviations. See § 3 for the full list.

---

### `conf.d/git-conventional.fish` — Conventional Commit Abbreviations

Conventional Commits format: `type(scope): description`
Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert.
Using this format enables automatic CHANGELOG generation and semantic versioning.

These are **abbreviations** (not aliases) — they expand in-place on Space so you
can complete the commit message inline before pressing Enter.

| Abbr | Expands to |
|------|-----------|
| `gcfeat` | `git commit -m "feat: "` |
| `gcfix` | `git commit -m "fix: "` |
| `gcdocs` | `git commit -m "docs: "` |
| `gcrefactor` | `git commit -m "refactor: "` |
| `gcperf` | `git commit -m "perf: "` |
| `gctest` | `git commit -m "test: "` |
| `gcchore` | `git commit -m "chore: "` |
| `gcbuild` | `git commit -m "build: "` |
| `gcci` | `git commit -m "ci: "` |
| `gcstyle` | `git commit -m "style: "` |
| `gcrev` | `git revert` |

---

### `conf.d/fzf.fish` — fzf Bindings (patrickf1/fzf.fish)

fzf.fish intercepts key bindings and opens fzf with context-aware lists.

| Binding | Action |
|---------|--------|
| `Ctrl-R` | search shell history |
| `Ctrl-T` | search files, insert path at cursor |
| `Ctrl-Alt-F` | search files, insert path at cursor (alternative) |
| `Alt-C` | cd into fuzzy-picked directory |

Preview commands set in `tools-fzf.fish`:
- `FZF_PREVIEW_FILE_CMD` → `bat --style=numbers --color=always --line-range :500`

---

### `conf.d/prompt-starship.fish` — Starship Prompt

Starship is a cross-shell prompt written in Rust.
Config lives at `~/.config/starship/starship.toml` — shared between fish and zsh.
Your prompt looks **identical** in both shells.

Current format: `$username$hostname$directory$character` on left (username/hostname
SSH-only), git + languages + duration + time on right.
Catppuccin Mocha palette defined in starship.toml via `[palettes.catppuccin_mocha]`.

---

### `conf.d/fnm.fish` — fnm (Fast Node Manager)

Runs `fnm env --use-on-cd | source` — auto-switches node version when entering
a directory with `.nvmrc` / `.node-version`. Mirrors the zsh setup.

---

### `conf.d/zoxide.fish` — Zoxide (kidonng/zoxide.fish)

zoxide tracks every directory you visit, weighted by frecency
(frequency + recency). It learns your habits.

| Command | What it does |
|---------|-------------|
| `z foo` | jump to most frecent dir matching "foo" |
| `z foo bar` | matching both "foo" and "bar" in path |
| `zi` | opens fzf to fuzzy-pick from history |

---

### `conf.d/tmux.fish` — Tmux Plugin (budimanjojo/tmux.fish)

wraps the `tmux` command to fix `$TERM`, auto-connect to existing
sessions, and provide directory-named session creation.

| Alias/function | What it does |
|----------------|-------------|
| `ta` | `tmux attach -t <session>` |
| `tad` | `tmux attach -d -t <session>` (detach others first) |
| `ts` | `tmux new-session -s <name>` |
| `tl` | `tmux list-sessions` |
| `tksv` | `tmux kill-server` |
| `tkss` | `tmux kill-session -t <name>` |
| `tds` | create/attach session named after current dir (path-hashed) |
| `tmuxconf` | open tmux config in `$EDITOR` |

---

## § 3  Git Abbreviations — jhillyerd/plugin-git

> Full list lives in the plugin source. Run `fish -c "abbr --list | grep ^g"` to see all ~150.

---

## § 4  functions/ — Autoloaded Functions

fish autoloads functions from `functions/`. You never `source` them.
The first time you call `mkcd`, fish reads `functions/mkcd.fish` and defines it.
After that it's in memory for the session. This is different from zsh where you'd
source a functions file explicitly.

### Navigation

#### `mkcd <path>`
`mkdir -p` then `cd` in one step. You almost always want to cd into the dir you just created.

#### `up [n]`
Go up N directories. `up 3` = `cd ../../..`. Default: 1.

#### `fcd [root]`
Fuzzy cd: uses `fd` to list all directories, `fzf` to pick interactively with
eza tree preview on the right. Starts from `root` (default: cwd).

#### `cl [dir]`
`cd` then immediately `eza -la --git --time-style=relative`. The most common
"what's in this directory" flow in one command.

---

### File Operations

#### `fe [root]`
Fuzzy-find a file with fzf (bat preview on right), open in `$EDITOR`.

#### `bak <file>`
Backup with timestamp: `config.json` → `config.json.bak.20240115-143022`.

#### `extract <archive>`
Universal extractor. Handles: `.tar.gz` `.tar.bz2` `.tar.xz` `.tar.zst` `.tar`
`.bz2` `.gz` `.zip` `.7z` `.rar` `.Z` `.zst`.

#### `mkenv [src] [dst]`
Copy `.env.example` → `.env`. Refuses to overwrite existing `.env`.

#### `json [file]`
Pretty-print JSON from file or stdin, rendered with bat syntax highlighting.

#### `dotenv_check`
List variable names (not values) defined in `.env`. Safe to share in logs.

---

### FZF Utilities

#### `fh`
Fuzzy history search. Puts selected command on the command line (doesn't run it).
Different from `Ctrl-R`: `fh` lets you preview and choose; `Ctrl-R` is faster.

#### `fkill [signal]`
Shows all processes in fzf (multi-select with Tab), kills selected ones.
Default signal: `-9`. Example: `fkill -15`.

#### `rgv <pattern> [path]`
ripgrep → fzf → open nvim at the **exact line**.
Shows syntax-highlighted file preview with the matching line highlighted.

---

### Git Functions

#### `gsf` — fuzzy branch switcher
Lists all local + remote branches in fzf. Preview shows recent commits on
that branch. Enter switches to it.

#### `gaf` — fuzzy git add
Shows changed files with diff preview. Tab to multi-select. Runs `git add`
on selection, then shows `git status -sb`.

#### `glf` — interactive log browser
Browse commits in fzf. Preview shows stats. Enter opens full diff in `less`.

#### `gdf` — fuzzy diff picker
Pick a changed file from fzf (live diff preview), then `git diff` it.

#### `wip`
Quick WIP commit: stages everything, commits with `"wip: YYYY-MM-DD HH:MM [skip ci]"`.
Different from `gwip` (which uses `--no-verify` and removes deleted files).

#### `unwip`
Undo the last `wip` commit. Checks the commit message starts with `wip:`.
Keeps all changes staged (`git reset HEAD~1`).

#### `gsync`
Fetch + rebase current branch on `origin/<main-branch>`.
The cleanest way to stay current without messy merge commits.
If already on main, just does `git pull --rebase`.

#### `gstat`
Show all local branches with ahead/behind counts vs `origin/<main-branch>`.

#### `gclone <url|user/repo> [dir]`
Clone and cd into the repo. Supports GitHub shorthand: `gclone user/repo`.

#### `prco <number>`
`gh pr checkout <number>` — requires the `gh` CLI.

#### `git_open`
Opens the current repo on GitHub in the default browser. Converts SSH URL
to HTTPS automatically.

#### `gbage`
List all local branches sorted by last commit date, with age and author.

#### `gbda [-g]`
Delete all merged branches — including **squash-merged** ones (detects via
`git cherry`). Pass `-g` / `--gone` to also delete branches whose remote
tracking ref is gone.

#### `grename <old> <new>`
Rename a branch locally and on origin. Updates the remote tracking ref.

---

### Tmux Functions

#### `fts` — fuzzy session switcher
Lists all tmux sessions in fzf with window preview. Enter switches to it.

#### `tdev [name] [root]`
Create a structured dev tmux session:
- Window 1 `editor`: opens `nvim .`
- Window 2 `dev`: horizontal split (run server left, run tests right)

If session already exists, attaches/switches to it.
Usage: `tdev` (uses cwd name), `tdev myproject ~/projects/myproject`

---

### Node / JS

#### `nvmuse`
Read `.nvmrc` or `.node-version` in cwd and switch node version.
Uses `fnm` if available (10x faster), falls back to `nvm`.

#### `pnscript`
Parse `package.json` scripts with Python, pick one in fzf, run with `pnpm run`.
Preview shows the script command before you run it.

---

### Network / System

#### `myip`
Shows local IP (en0/en1 on macOS, `ip route` on Linux) and public IP via `api.ipify.org`.

#### `serve [port]`
One-liner HTTP server in cwd using `python3 -m http.server`. Default port: 8080.
Shows local and LAN URLs.

---

### Dotfiles Management

#### `stow_pkg <package>`
Stow a single dotfiles package:
```
stow_pkg zsh   → symlinks ~/.dotfiles/.config/zsh → ~/.config/zsh
```

#### `stow_all`
Restow every package in `~/.dotfiles/.config/`. Skips `alacritty`, `kitty`,
`wezterm` if the binary isn't installed (conditional packages).

