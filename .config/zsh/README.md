# ZSH Configuration

A modern, XDG-compliant ZSH setup built around **Antidote**, **Starship**, and the
Catppuccin Mocha colour palette. Works identically on macOS (Apple Silicon + Intel)
and Linux. Every file lives in `~/.config/zsh/` — tracked by git via GNU Stow.

---

## Table of Contents

1. [Directory structure](#directory-structure)
2. [Load order — how ZSH reads files](#load-order--how-zsh-reads-files)
3. [File reference](#file-reference)
   - [~/.zshenv (root)](#zshenv-at-)
   - [.zshenv](#zdotdirzshenvconfigzshzshenv)
   - [.zprofile](#zdotdirzprofileconfigzshzprofile)
   - [.zshrc](#zdotdirzshrc--the-main-file)
   - [.zsh\_plugins.txt](#zdotdirzsh_pluginstxt)
   - [conf.d/aliases.zsh](#confdaliaseszsh)
   - [conf.d/functions.zsh](#condfunctionszsh)
   - [conf.d/git.zsh](#confdgitzsh)
   - [conf.d/completions.zsh](#confdcompletionszsh)
4. [Plugins — every one explained](#plugins--every-one-explained)
5. [Aliases — full reference](#aliases--full-reference)
6. [Functions — full reference](#functions--full-reference)
7. [Key bindings](#key-bindings)
8. [Colour system](#colour-system)
9. [Environment variables](#environment-variables)
10. [Install & first run](#install--first-run)
11. [Adding a new plugin](#adding-a-new-plugin)
12. [Profiling startup time](#profiling-startup-time)

---

## Directory structure

```
~/.dotfiles/
├── install.sh                    ← run once after cloning
├── .zshenv                       ← THE ONLY FILE AT ~/  (sets ZDOTDIR)
└── .config/
    └── zsh/                      ← $ZDOTDIR, stowed to ~/.config/zsh/
        ├── README.md             ← this file
        ├── .zshenv               ← env vars, PATH (all shell types)
        ├── .zprofile             ← login-shell once-per-session setup
        ├── .zshrc                ← interactive shell config (12 sections)
        ├── .zsh_plugins.txt      ← antidote plugin list (plain text)
        ├── .zsh_plugins.zsh      ← antidote compiled output (gitignored)
        └── conf.d/
            ├── aliases.zsh
            ├── functions.zsh
            ├── git.zsh
            └── completions.zsh
```

GNU Stow creates symlinks:
`~/.config/zsh/` → `~/.dotfiles/.config/zsh/`
`~/.zshenv`      → `~/.dotfiles/.zshenv`

Edit files in `~/.dotfiles/`. All tools see them through symlinks. One `git pull` updates every machine.

---

## Load order — how ZSH reads files

ZSH loads files in a strict sequence. Understanding this is the key to understanding
why each file exists.

```
Every shell (scripts, SSH, cron, interactive):
  1. ~/.zshenv              → sets ZDOTDIR, nothing else
  2. $ZDOTDIR/.zshenv       → PATH, env vars, exports

Login shells only (first terminal open, SSH session):
  3. $ZDOTDIR/.zprofile     → brew shellenv, fnm, version managers

Interactive shells (every new tab, pane, exec zsh):
  4. $ZDOTDIR/.zshrc        → everything else: plugins, aliases, prompt
```

**Login vs interactive:** opening your terminal app = login + interactive.
A new tmux pane = interactive only (not login). This matters because `.zprofile`
only runs once per session while `.zshrc` runs for every pane.

**The ZDOTDIR trick:** `~/.zshenv` sets `export ZDOTDIR="$HOME/.config/zsh"`.
After that, ZSH looks for all other config files inside `$ZDOTDIR` instead of `~/`.
This keeps `~/` clean — only `~/.zshenv` sits there.

---

## File reference

### `~/.zshenv` (at `~/`)

The only file not inside `.config/zsh/`. One line:

```zsh
export ZDOTDIR="$HOME/.config/zsh"
```

That's it. Redirect everything else to ZDOTDIR. Stowed via `ln -sf` by `install.sh`
because Stow manages `.config/*` packages, not root-level dotfiles.

---

### `$ZDOTDIR/.zshenv` (`~/.config/zsh/.zshenv`)

Runs for **every** shell type — interactive, non-interactive, scripts, SSH commands.
Rule: **no subprocess forks, no eval, no output**. Pure variable assignments only.

| Variable | Value | Why here |
|---|---|---|
| `XDG_CONFIG_HOME` | `~/.config` | XDG spec — standardises app config locations |
| `XDG_CACHE_HOME` | `~/.cache` | XDG spec |
| `XDG_DATA_HOME` | `~/.local/share` | XDG spec |
| `XDG_STATE_HOME` | `~/.local/state` | XDG spec |
| `HISTFILE` | `~/.local/state/zsh/history` | Out of git-tracked ZDOTDIR |
| `ZSH_COMPDUMP` | `~/.cache/zsh/zcompdump-$ZSH_VERSION` | Out of git-tracked ZDOTDIR |
| `ANTIDOTE_HOME` | `~/.local/share/antidote` | XDG-compliant plugin storage |
| `EDITOR` | `nvim` | Used by git, cron, any tool spawning an editor |
| `VISUAL` | `nvim` | Terminal visual editor (some tools check this) |
| `GIT_EDITOR` | `nvim` | Git-specific override (commit msg, rebase, etc.) |
| `PAGER` | `less` | Default pager |
| `LESS` | `-R -F -X` | Pass ANSI colours; quit if fits screen; no clear |
| `MANPAGER` | `sh -c 'col -bx \| bat -l man -p'` | Syntax-highlighted man pages via bat |
| `LANG` / `LC_ALL` | `en_US.UTF-8` | Consistent locale everywhere |
| `HOMEBREW_PREFIX` | `/opt/homebrew` or `/usr/local` | Set here so PATH can reference it |
| `PATH` | `$HOMEBREW_PREFIX/bin:...` | Brew, local bin, pnpm, bun, go |
| `HOMEBREW_NO_ANALYTICS` | `1` | Don't phone home |
| `HOMEBREW_NO_AUTO_UPDATE` | `1` | Update on your terms, not brew's |
| `PNPM_HOME` | `~/.local/share/pnpm` | XDG-compliant pnpm location |
| `BUN_INSTALL` | `~/.bun` | Bun default |
| `GOPATH` | `~/.local/share/go` | XDG-compliant Go workspace |
| `JAVA_HOME` | `/Library/.../zulu-17.jdk/...` | React Native Android builds. Guard-checked — no-op if path absent |
| `ANDROID_HOME` | `~/Library/Android/sdk` | React Native Android. Guard-checked. Adds `emulator` + `platform-tools` to PATH |
| `BAT_THEME` | `Catppuccin Mocha` | Syntax highlight theme for bat / MANPAGER |
| `RIPGREP_CONFIG_PATH` | `~/.config/ripgrep/config` | rg reads this file for default flags |
| `FZF_DEFAULT_OPTS` | Catppuccin Mocha colours + layout | All fzf invocations inherit this |
| `FZF_DEFAULT_COMMAND` | `fd --type f --hidden ...` | fzf uses fd instead of find |
| `FZF_CTRL_T_OPTS` | bat file preview | Ctrl-T file picker has a preview panel |
| `FZF_ALT_C_OPTS` | eza tree preview | Alt-C dir picker has a tree preview |
---

### `$ZDOTDIR/.zprofile` (`~/.config/zsh/.zprofile`)

Runs **once per login shell**. Use for things that spawn subprocesses — they're slow,
so we don't want them running for every new tmux pane.

**Homebrew shellenv** — `eval "$(/opt/homebrew/bin/brew shellenv)"` (Apple Silicon) or
`/usr/local/bin/brew` (Intel). Sets `HOMEBREW_CELLAR`, `HOMEBREW_REPOSITORY`,
`INFOPATH`, `MANPATH`. Uses hardcoded paths because `HOMEBREW_PREFIX` from `.zshenv`
may not be in the environment at this point on a fresh shell.

**pyenv** — `eval "$(pyenv init -)"` — Python version manager, login shell only.

**rbenv** — `eval "$(rbenv init -)"` — Ruby version manager, login shell only.

**fnm** — Node version manager. `eval "$(fnm env --use-on-cd --install-if-missing)"` —
auto-switches Node version on `cd`, auto-installs missing versions.

---

### `$ZDOTDIR/.zshrc` — the main file

Loaded for **every interactive shell**: new terminal, new tmux pane, `exec zsh`.
Sections run in order — order matters.

#### § 1 — Completion system

Adds Homebrew's `site-functions` to `$fpath` first (macOS). Then runs `compinit`
with a 20-hour cache strategy: if `.zcompdump` is younger than 20 hours, use the
cache (`-C` = skip security check). Otherwise rescan all of `$fpath` and rebuild.

`zstyle` rules configure the completion UI:
- `menu select` — arrow-key navigable menu
- `matcher-list` — case-insensitive, then partial-word, then substring matching
- `list-colors` — colours the completion menu using `$LS_COLORS`
- Category headers, group separation, SSH host completion, kill PID completion

#### § 2 — Antidote

Antidote reads `.zsh_plugins.txt`, clones each plugin into `$ANTIDOTE_HOME`,
and writes `.zsh_plugins.zsh` — a static file of `source` statements.
After first run: no network, no parsing. Just one file sourced.

Auto-bootstrap: if antidote isn't installed, it clones itself.
Auto-recompile: if `.zsh_plugins.txt` is newer than `.zsh_plugins.zsh`, it rebundles.

#### § 3 — History

```
HISTSIZE=200000    # lines in RAM
SAVEHIST=200000    # lines written to disk
```

Key options:
- `HIST_IGNORE_ALL_DUPS` — deletes older duplicate anywhere in history (not just adjacent)
- `HIST_IGNORE_SPACE` — lines starting with a space are never saved (useful for secrets)
- `SHARE_HISTORY` — all open shells share one live history (new command in tab A visible in tab B's Ctrl-R immediately)
- `EXTENDED_HISTORY` — stores `: timestamp:duration;command` in history file

#### § 4 — Shell options

| Option | Effect |
|---|---|
| `AUTO_CD` | Type a directory name alone → cd into it |
| `AUTO_PUSHD` | Every `cd` pushes the old dir onto a stack |
| `PUSHD_IGNORE_DUPS` | Don't push duplicates onto the stack |
| `GLOB_DOTS` | `*` matches dotfiles without needing `.*` |
| `EXTENDED_GLOB` | `^pattern`, `(#i)case-insensitive`, `**/` recursive |
| `NULL_GLOB` | Unmatched glob expands to empty, not an error |
| `CORRECT` | Suggests corrections for mistyped commands |
| `NO_BEEP` | Silence |
| `INTERACTIVE_COMMENTS` | Allow `# comments` at the interactive prompt |
| `MULTIOS` | `cmd > f1 > f2` writes to both files |
| `RC_QUOTES` | `'it''s'` → `"it's"` inside single-quoted strings |

#### § 5 — Vi mode

Uses `jeffreytse/zsh-vi-mode` (not the built-in `bindkey -v`) because the built-in
breaks fzf bindings, has no cursor shape changes, and no text objects.

Configuration set **before** the plugin loads:
- `ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT` — start every line in insert mode
- `ZVM_VI_INSERT_ESCAPE_BINDKEY=jk` — `jk` exits insert mode (faster than Esc)
- Cursor shapes: `|` beam in insert, `█` block in normal, `_` underline in operator-pending

`zvm_after_init()` hook — fires after vi-mode finishes initialising its keymap.
Used to restore fzf bindings (which vi-mode overwrites) and set up
history-substring-search in both the `main` and `vicmd` keymaps.

#### § 6 — Plugin configuration

After antidote loads the plugins, these settings configure their behaviour:

- `ZSH_AUTOSUGGEST_STRATEGY=(history completion)` — try history first, fall back to completion engine
- `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"` — Catppuccin Surface 2 (subtle grey ghost text)
- `ZSH_AUTOSUGGEST_USE_ASYNC=1` — suggestions fetched in background, no typing lag
- `FAST_HIGHLIGHT_STYLES[*]` — 17 token types mapped to Catppuccin Mocha hex values
- `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND` — Catppuccin green on match
- `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND` — Catppuccin red on no match
- `YSU_MESSAGE_FORMAT` — "alias hint" reminder styled in Catppuccin yellow/green
- fzf-tab `zstyle` per-command previews — cd shows eza tree, files show bat content,
  git subcommands show diffs/logs, kill shows process details

#### § 7 — Colours

Colour pipeline:
```
vivid (catppuccin-mocha theme)
  → generates LS_COLORS string (200+ file types)
    → zsh completion menu + eza + fzf previews inherit it
      → EZA_COLORS extends it with 15 eza-specific column keys
        → FAST_HIGHLIGHT_STYLES adds command-line token colours
          → all hex values trace to the official Catppuccin Mocha palette
```

`EZA_COLORS` keys:
`uu`/`gu` (user/group columns), `sn`/`sb` (size number/unit), `da` (date),
`ga`/`gm`/`gd`/`gr` (git Added/Modified/Deleted/Renamed), `hd` (header row),
`lp` (symlink target), permission bits (`ur`/`uw`/`ux`, `gw`/`gx`, `tw`/`tx`)

#### § 8 — Tools init

- `starship init zsh` — cross-shell prompt. Reads `~/.config/starship.toml` (shared with Fish)
- `zoxide init zsh` — adds `z` (frecency jump) and `zi` (fzf picker)
- `fnm env --use-on-cd --install-if-missing` — auto-switches Node version on `cd`, auto-installs missing versions

#### § 9-12 — Modular configs + local override

Sources every `conf.d/*.zsh` file in alphabetical order.
Then sources `$ZDOTDIR/.zshrc.local` if it exists (not tracked by git — for
machine-specific secrets, work API tokens, etc.).

---

### `$ZDOTDIR/.zsh_plugins.txt`

Plain text file. One plugin per line. Antidote reads this and compiles it into
`.zsh_plugins.zsh`. Editing this file triggers a recompile on next shell start.

See [Plugins — every one explained](#plugins--every-one-explained) below.

---

### `conf.d/aliases.zsh`

Pure text substitutions — no logic, no arguments.
See [Aliases — full reference](#aliases--full-reference) below.

---

### `conf.d/functions.zsh`

Shell functions with arguments, logic, fzf integrations.
See [Functions — full reference](#functions--full-reference) below.

---

### `conf.d/git.zsh`

Git-specific shell config that doesn't fit in aliases:
- `GIT_PAGER="delta"` — pipes all git output through delta for syntax-highlighted diffs
- Conventional commit type aliases (`gcfeat`, `gcfix`, `gcchore`, etc.)
- `git-main-branch()` — detects whether the repo uses `main` or `master`
- `gsync` — fetch origin/main, rebase current branch onto it
- `gstat` — show ahead/behind counts for every local branch vs main

---

### `conf.d/completions.zsh`

Tool-generated completions, cached to files.

Pattern: instead of `eval "$(tool completion zsh)"` on every shell start (slow — forks
a process each time), we run the command once, write output to a cache file, and source
the file. Cache is invalidated when the tool binary changes (mtime comparison).

Cached: `gh`, `docker`, `kubectl`, `helm`, `pnpm`, `rustup`, `starship`, `fnm`.

---

## Plugins — every one explained

Managed by **Antidote**. Source of truth: `.zsh_plugins.txt`.

| # | Plugin | What it does | Why this one |
|---|---|---|---|
| 1 | `zsh-users/zsh-completions` | ~100 extra completion definitions (docker-compose, pip, cargo…) | Loaded as `kind:fpath` — adds to `$fpath`, compinit finds it |
| 2 | `zdharma-continuum/fast-syntax-highlighting` | Colours commands as you type. Green = valid, red = not found | 2-3× faster than `zsh-syntax-highlighting`, more token types, themeable |
| 3 | `zsh-users/zsh-autosuggestions` | Fish-style ghost text from history. `→` or `Ctrl-F` to accept | Strategy: history first, then completion engine. Async — no lag |
| 4 | `zsh-users/zsh-history-substring-search` | `↑`/`↓` searches history for entries *containing* what you typed, not just starting with it | Highlighted in green (found) or red (not found) |
| 5 | `Aloxaf/fzf-tab` | Replaces ZSH completion menu with fzf. Per-command previews | Tab on `cd` shows eza tree. Tab on files shows bat content. Tab on `kill` shows process |
| 6 | `jeffreytse/zsh-vi-mode` | Full vim keybindings: text objects (`ciw`, `da"`), surround, cursor shapes | Built-in `bindkey -v` breaks fzf and has no text objects. This plugin provides `zvm_after_init()` hook |
| 7 | `hlissner/zsh-autopair` | Auto-closes `()`, `[]`, `{}`, `""`, `''`. Backspace on empty pair deletes both | Zero config, handles edge cases (won't double-close if you type the closing char) |
| 8 | `kutsan/zsh-system-clipboard` | Vi-mode `y`/`d`/`p` interact with the system clipboard, not just ZSH's kill ring | Auto-detects pbcopy (macOS), xclip/xsel (X11), wl-copy (Wayland) |
| 9 | `MichaelAquilina/zsh-you-should-use` | After running a command, reminds you if an alias exists for it | Trains alias muscle memory. Configured with `YSU_MESSAGE_POSITION=after` |
| 10 | `mollifier/cd-gitroot` | `cdg` — jump to the root of the current git repo instantly | Complements `groot` alias; useful when deep in nested directories |
| 11 | `conf.d/dotenv.zsh` (native) | Auto-sources `.env` when you `cd` into a directory | Asks confirmation first time. Allow/deny lists in `~/.cache/zsh/` (proper XDG paths) |
| 12 | `conf.d/magic-enter.zsh` (native) | Press `Enter` on empty prompt → `git status` in a repo, `eza -la` elsewhere | Saves the most common "what's here?" command |

**Fallback note:** Plugin #2 can be swapped back to `zsh-users/zsh-syntax-highlighting`
by commenting out `zdharma-continuum/fast-syntax-highlighting` and uncommenting the
fallback line in `.zsh_plugins.txt`. Both are compatible with fzf-tab and autosuggestions.

---

## Aliases — full reference

### eza (ls replacement)

| Alias | Command | Use case |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | Default listing |
| `l` | `eza ... -1` | Single column |
| `ll` | `eza ... -la --git --header --time-style=relative` | Long listing — daily driver |
| `la` | `eza ... -lA --git --header` | Include hidden files |
| `lt` | `eza --tree --level=2` | Project structure overview |
| `ltt` | `eza --tree --level=3` | Deeper tree |
| `ltl` | `eza --tree --level=2 -la --git` | Tree + details |
| `lg` | `eza ... --git-ignore` | Hide gitignored files |
| `lm` | `eza ... --sort=modified --reverse` | What changed recently? |
| `lz` | `eza ... --sort=size --reverse` | Largest files first |
| `ldu` | `eza ... --total-size --sort=size --reverse` | Directory sizes |

### bat (cat replacement)

| Alias | Notes |
|---|---|
| `cat` | `bat --paging=never --style=plain` — drop-in cat with highlighting |
| `catn` | With line numbers + git change gutter |
| `catp` | With paging (like `less` but highlighted) |
| `batdiff` | Show only changed lines |

### Navigation

| Alias | Notes |
|---|---|
| `..` `...` `....` `.....` | cd up 1–4 levels |
| `-` | `cd -` — previous directory |
| `d` | `dirs -v` — show directory stack |
| `1`–`9` | Jump to position in directory stack |

### Git — status

| Alias | Command |
|---|---|
| `g` | `git` |
| `gs` | `git status -sb` — short with branch |
| `gss` | `git status` — full |

### Git — staging

| Alias | Command |
|---|---|
| `ga` | `git add` |
| `gaa` | `git add -A` |
| `gap` | `git add -p` — interactive hunk staging |
| `gai` | `git add -i` — interactive menu |

### Git — committing

| Alias | Command |
|---|---|
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gca` | `git commit --amend` |
| `gcane` | `git commit --amend --no-edit` |
| `gcem` | `git commit --allow-empty -m` — trigger CI |
| `gcf` | `git commit --fixup` — for `rebase --autosquash` |
| `gcfeat` | `git commit -m "feat: "` — conventional commit |
| `gcfix` | `git commit -m "fix: "` |
| `gcchore` | `git commit -m "chore: "` |
| `gcdocs` | `git commit -m "docs: "` |
| `gcrefactor` | `git commit -m "refactor: "` |
| `gcperf` | `git commit -m "perf: "` |
| `gctest` | `git commit -m "test: "` |
| `gcbuild` | `git commit -m "build: "` |
| `gcci` | `git commit -m "ci: "` |

### Git — branches (2026: switch/restore over checkout)

| Alias | Command | Notes |
|---|---|---|
| `gsw` | `git switch` | Modern branch switch |
| `gswc` | `git switch -c` | Create + switch |
| `gswm` | `git switch main` | Switch to main/master |
| `gr` | `git restore` | Discard file changes |
| `grs` | `git restore --staged` | Unstage |
| `gco` | `git checkout` | Kept for muscle memory |
| `gcob` | `git checkout -b` | Legacy create+switch |

### Git — diff

| Alias | Command |
|---|---|
| `gd` | `git diff` — unstaged |
| `gds` | `git diff --staged` — what you'll commit |
| `gdt` | `git diff --stat` — summary |
| `gdw` | `git diff --word-diff` — word-level |
| `gdo` | `git diff origin/HEAD` — vs remote |

### Git — log

| Alias | Command |
|---|---|
| `glog` | `git log --oneline --graph --decorate --all` |
| `gloga` | Same + author + relative date |
| `gln` | Last 10 commits |
| `glp` | Full diff log |
| `gll` | Log with file stats |

### Git — push/pull/fetch

| Alias | Command |
|---|---|
| `gp` | `git push` |
| `gpf` | `git push --force-with-lease` — safe force |
| `gpff` | `git push --force` — DANGER |
| `gpu` | `git push -u origin HEAD` — new branch |
| `gl` | `git pull` |
| `glr` | `git pull --rebase` |
| `gf` | `git fetch` |
| `gfa` | `git fetch --all --prune` |

### Git — rebase

| Alias | Command |
|---|---|
| `grb` | `git rebase` |
| `grbi` | `git rebase -i` |
| `grbia` | `git rebase -i --autosquash` |
| `grbc` | `git rebase --continue` |
| `grba` | `git rebase --abort` |

### Git — stash

| Alias | Command |
|---|---|
| `gst` | `git stash` |
| `gsta` | `git stash push -u` — include untracked |
| `gstp` | `git stash pop` |
| `gstl` | `git stash list` |
| `gstd` | `git stash drop` |
| `gsts` | `git stash show -p` |

### Git — branches

| Alias | Command |
|---|---|
| `gbr` | `git branch` |
| `gbra` | `git branch -a` — all including remote |
| `gbrv` | `git branch -vv` — upstream + ahead/behind |
| `gbrd` | `git branch -d` — safe delete |
| `gbrD` | `git branch -D` — force delete |
| `gbrsort` | `git branch --sort=-committerdate` |
| `gbrclean` | Delete all merged branches |

### Git — reset (DANGER)

| Alias | Command |
|---|---|
| `grh` | `git reset HEAD` — unstage all |
| `grhh` | `git reset --hard HEAD` — discard everything |
| `grhs` | `git reset --soft HEAD~1` — undo commit, keep staged |
| `grhm` | `git reset --mixed HEAD~1` — undo commit, keep unstaged |

### Git — worktrees

| Alias | Command |
|---|---|
| `gwt` | `git worktree` |
| `gwta` | `git worktree add` — check out branch into new dir |
| `gwtl` | `git worktree list` |
| `gwtr` | `git worktree remove` |

### Git — misc

| Alias | Command |
|---|---|
| `groot` | `cd $(git rev-parse --show-toplevel)` |
| `ghash` | `git rev-parse --short HEAD` |
| `gurl` | `git remote get-url origin` |
| `gwip` | Quick WIP commit (function — see functions) |
| `gunwip` | Undo last WIP commit |
| `gopen` | Open repo in browser |

### tmux

| Alias | Command |
|---|---|
| `t` | `tmux` |
| `T` | `tmux new-session -A -s main` — attach or create "main" |
| `ta` | `tmux attach -t` |
| `tn` | `tmux new-session -s` |
| `tl` | `tmux list-sessions` |
| `tk` | `tmux kill-session -t` |
| `tka` | `tmux kill-server` — kill everything |
| `ts` | `tmux switch-client -t` |
| `tad` | `tmux attach -d -t` — detach others, then attach |
| `tw` | `tmux list-windows` |
| `trn` | `tmux rename-session` |
| `tpk` | `tmux kill-pane` |
| `tsrc` | `tmux source-file ~/.config/tmux/tmux.conf` |

### pnpm / Node

| Alias | Command |
|---|---|
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
| `pnup` | `pnpm update --interactive --latest` |
| `pnclean` | Remove node_modules, .turbo, dist → reinstall |

### React Native / Expo

| Alias | Command |
|---|---|
| `rni` | `npx react-native run-ios` |
| `rna` | `npx react-native run-android` |
| `rnios` | Run on iPhone 15 Pro simulator |
| `pods` | `cd ios && bundle exec pod install && cd ..` |
| `rnclean` | Watchman + full clean rebuild |
| `expod` | `npx expo start` |
| `expodc` | `npx expo start --clear` |

### ripgrep / fd

| Alias | Command |
|---|---|
| `rg` | `rg --color=always --smart-case` |
| `rgi` | Force case-insensitive |
| `rgf` | Files with matches only |
| `rgts` | Search TypeScript files only |
| `rgjs` | Search JS files only |
| `fd` | `fd --color=always` |
| `fdf` | Files only |
| `fdd` | Dirs only |
| `fdh` | Include hidden |

### System

| Alias | Command |
|---|---|
| `reload` | `exec zsh` — clean restart |
| `reloads` | `source $ZDOTDIR/.zshrc` — soft reload |
| `path` | Print PATH one entry per line, numbered |
| `ports` | Show listening ports |
| `df` | `df -h` — human sizes |
| `du` | `du -sh` — dir size |
| `dua` | All items sorted by size |

### Dotfiles quick access

| Alias | Opens |
|---|---|
| `dot` | `cd ~/.dotfiles` |
| `zrc` | `nvim $ZDOTDIR/.zshrc` |
| `zenv` | `nvim $ZDOTDIR/.zshenv` |
| `zalias` | `nvim conf.d/aliases.zsh` |
| `zfn` | `nvim conf.d/functions.zsh` |
| `zplug` | `nvim .zsh_plugins.txt` |

### Clipboard

| Alias | Platform |
|---|---|
| `copy` / `paste` | `pbcopy`/`pbpaste` (macOS), `wl-copy`/`wl-paste` (Wayland), `xclip` (X11) |

### Global aliases (expand anywhere on the line)

| Alias | Expands to |
|---|---|
| `NUL` | `>/dev/null 2>&1` |
| `NULL` | `2>/dev/null` |
| `G` | `\| grep` |
| `GI` | `\| grep -i` |
| `L` | `\| less` |
| `H` | `\| head` |
| `T` | `\| tail` |
| `TF` | `\| tail -f` |
| `WC` | `\| wc -l` |
| `JSON` | `\| python3 -m json.tool` |

### macOS-only

| Alias | Command |
|---|---|
| `o` | `open` |
| `ql` | QuickLook preview |
| `flushdns` | Flush DNS cache |
| `showfiles` | Show hidden files in Finder |
| `hidefiles` | Hide them |
| `update` | `brew update && upgrade && cleanup` |
| `brewdump` | Save Brewfile snapshot to dotfiles |
| `awake` | `caffeinate -d` — prevent sleep |

---

## Functions — full reference

All functions live in `conf.d/functions.zsh` and `conf.d/git.zsh`.

### Navigation

| Function | Usage | What it does |
|---|---|---|
| `mkcd` | `mkcd src/components/Button` | `mkdir -p` + `cd` in one step |
| `up` | `up 3` | Go up N directories |
| `fcd` | `fcd` or `fcd src/` | Fuzzy cd: fd + fzf + eza tree preview |
| `cl` | `cl src/` | `cd` then immediately `eza -la` |

### Files

| Function | Usage | What it does |
|---|---|---|
| `fe` | `fe` or `fe src/` | Fuzzy find file → open in `$EDITOR`. bat preview |
| `bak` | `bak config.json` | Copies to `config.json.bak.20240115-143022` |
| `extract` | `extract archive.tar.gz` | Universal extractor — handles 11 formats |
| `rgv` | `rgv "useState"` | rg → fzf → opens nvim at exact matching line |
| `json` | `cat data.json \| json` | Pretty-print JSON with bat highlighting |

### Git (interactive)

| Function | Usage | What it does |
|---|---|---|
| `gswitch` | `gswitch` | Fuzzy branch picker. Preview: last 15 commits per branch |
| `gadd` | `gadd` | Fuzzy interactive staging. Preview: diff per file. Multi-select with Tab |
| `gshow` | `gshow` | Browse git log in fzf. Preview: full diff. Enter opens in less |
| `gdiff` | `gdiff` | Pick file from `git status` → show its diff |
| `gwip` | `gwip` | Stage everything → commit `"wip: 2024-01-15 14:23 [skip ci]"` |
| `gunwip` | `gunwip` | Undo last wip commit, keep changes staged |
| `gclone` | `gclone user/repo` | Clone (expands GitHub shorthand) → cd into it |
| `gpr` | `gpr 42` | `gh pr checkout 42` |
| `gopen` | `gopen` | Open current repo on GitHub in browser |
| `gsync` | `gsync` | Fetch origin/main → rebase current branch onto it |
| `gstat` | `gstat` | Show ahead/behind vs main for every local branch |

### tmux

| Function | Usage | What it does |
|---|---|---|
| `fts` | `fts` | Fuzzy tmux session switcher. Preview: windows in each session |
| `tdev` | `tdev` or `tdev myproject` | Spawn structured session: window 1 = nvim, window 2 = split panes |

### Node / JS

| Function | Usage | What it does |
|---|---|---|
| `nvmuse` | `nvmuse` | Read `.nvmrc`/`.node-version` → switch via fnm (auto-installs if missing) |
| `pnscript` | `pnscript` | Parse `package.json` scripts → fzf picker → run selected |

### System

| Function | Usage | What it does |
|---|---|---|
| `fh` | `fh` | Fuzzy history search → puts selection in buffer (doesn't run immediately) |
| `fkill` | `fkill` or `fkill -15` | Fuzzy process picker → kill. Multi-select with Tab |
| `myip` | `myip` | Show local + public IP |
| `serve` | `serve` or `serve 3000` | Python HTTP server in current dir |

### Dotfiles

| Function | Usage | What it does |
|---|---|---|
| `stow-pkg` | `stow-pkg zsh` | Restow a single package |
| `stow-all` | `stow-all` | Restow every package in `.dotfiles/.config/` |

### Misc

| Function | Usage | What it does |
|---|---|---|
| `mkenv` | `mkenv` | Copy `.env.example` → `.env` |
| `dotenv-check` | `dotenv-check` | List `.env` variable names without showing values |

---

## Key bindings

All bindings are set inside `zvm_after_init()` in `.zshrc` to survive vi-mode's
keymap reset.

### Insert mode

| Key | Action |
|---|---|
| `jk` | Exit to normal mode (faster than Esc) |
| `Ctrl-Space` | Accept autosuggestion |
| `Ctrl-F` | Accept autosuggestion (fish-style) |
| `Ctrl-R` | fzf history search |
| `Ctrl-T` | fzf file picker (inserts path) |
| `Alt-C` | fzf directory picker (cd) |
| `↑` / `Ctrl-P` | History substring search up |
| `↓` / `Ctrl-N` | History substring search down |
| `Ctrl-A` | Beginning of line |
| `Ctrl-E` | End of line |
| `Ctrl-K` | Kill to end of line |
| `Ctrl-U` | Kill to start of line |
| `Ctrl-Right` | Forward word |
| `Ctrl-Left` | Backward word |
| `Ctrl-Delete` | Kill next word |
| `Ctrl-Backspace` | Kill previous word |
| `Home` / `End` | Start / end of line |

### Normal mode (after `jk` or `Esc`)

| Key | Action |
|---|---|
| `h` `j` `k` `l` | Move cursor |
| `j` / `k` | History substring search down/up |
| `w` `b` `e` | Word navigation |
| `0` `$` | Line start / end |
| `ciw` | Change inner word |
| `da"` `di(` | Delete around/inside quotes/parens |
| `v` | Open command in `$EDITOR` |
| `y` | Yank to system clipboard |
| `p` | Paste from system clipboard |

---

## Colour system

All colours trace to the **Catppuccin Mocha** palette.

| Name | Hex | Used for |
|---|---|---|
| Base | `#1e1e2e` | Terminal background |
| Surface 0 | `#313244` | fzf selected line bg |
| Surface 2 | `#585b70` | Autosuggestion ghost text |
| Overlay 0 | `#6c7086` | Comments, secondary text |
| Text | `#cdd6f4` | Foreground |
| Rosewater | `#f5e0dc` | fzf spinner, cursor |
| Flamingo | `#f2cdcd` | — |
| Pink | `#f5c2e7` | — |
| Mauve | `#cba6f7` | Reserved words, prompt, fzf info |
| Red | `#f38ba8` | Errors, unknown commands, fzf hl |
| Peach | `#fab387` | Back-quoted args |
| Yellow | `#f9e2af` | Variables, assignments, warnings |
| Green | `#a6e3a1` | Valid commands, git added, fzf marker |
| Teal | `#94e2d5` | — |
| Sky | `#89dceb` | Builtins |
| Blue | `#89b4fa` | Dates, paths |
| Lavender | `#b4befe` | — |

Applied via:
- `vivid generate catppuccin-mocha` → `LS_COLORS`
- `EZA_COLORS` — eza column colours (15 keys)
- `FAST_HIGHLIGHT_STYLES` — 17 token type colours
- `FZF_DEFAULT_OPTS` — fzf UI colours
- `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND/NOT_FOUND`
- `BAT_THEME="Catppuccin Mocha"`

---

## Environment variables

Quick reference — where each important variable is set and why.

| Variable | File | Value |
|---|---|---|
| `ZDOTDIR` | `~/.zshenv` | `~/.config/zsh` |
| `EDITOR` / `VISUAL` | `.zshenv` | `nvim` |
| `GIT_EDITOR` | `.zshenv` | `nvim` |
| `HISTFILE` | `.zshenv` | `~/.local/state/zsh/history` |
| `JAVA_HOME` | `.zshenv` | Zulu JDK 17 path (guard-checked) |
| `ANDROID_HOME` | `.zshenv` | `~/Library/Android/sdk` (guard-checked) |
| `HOMEBREW_PREFIX` | `.zshenv` | `/opt/homebrew` or `/usr/local` |
| `BAT_THEME` | `.zshenv` | `Catppuccin Mocha` |
| `FZF_DEFAULT_OPTS` | `.zshenv` | Catppuccin colours + layout |
| `ANTIDOTE_HOME` | `.zshenv` | `~/.local/share/antidote` |
| `ZSH_AUTOSUGGEST_STRATEGY` | `.zshrc §6` | `(history completion)` |
| `ZVM_VI_INSERT_ESCAPE_BINDKEY` | `.zshrc §5` | `jk` |
| `GIT_PAGER` | `git.zsh` | `delta` |

---

## Adding a new plugin

1. Add a line to `.zsh_plugins.txt`:
   ```
   author/repo
   ```
2. Open a new shell — antidote detects `.txt` is newer than `.zsh`, recompiles automatically.
3. Configure the plugin in `.zshrc §6` if needed.

---

## Profiling startup time

```bash
# In .zshrc, uncomment line 1:
zmodload zsh/zprof

# And the last line:
# zprof

# Open a new shell, type:
zprof
```

Or use hyperfine for a clean benchmark:

```bash
brew install hyperfine
hyperfine --warmup 3 "zsh -i -c exit"
```

Typical targets: < 100ms first run (antidote bundling), < 50ms subsequent runs.
