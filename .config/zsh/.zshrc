# ══════════════════════════════════════════════════════════════════════════════
# $ZDOTDIR/.zshrc  ·  interactive shell config
# ══════════════════════════════════════════════════════════════════════════════
#
# ZSH has a strict load order. Every time you open a terminal (or a new tmux
# pane, or run `exec zsh`) ZSH loads files in this sequence:
#
#   .zshenv   → always (scripts, SSH, non-interactive, everything)
#   .zprofile → login shells only (once per session open)
#   .zshrc    → interactive shells  ← THIS FILE
#   .zlogin   → login shells, after .zshrc
#
# .zshrc is the file you actually live in. It runs every time you get a
# prompt. Rules:
#   ✓ aliases, functions, keybindings, prompt, plugins, completions
#   ✗ env vars (those go in .zshenv — scripts need them too)
#   ✗ anything that prints output unconditionally
#   ✗ slow things that could be lazy-loaded

# ── Guard: bail if not interactive ────────────────────────────────────────────
# If ZSH is sourcing this as a script (rare but possible), stop here.
[[ $- == *i* ]] || return

# ── Profiling ─────────────────────────────────────────────────────────────────
# Uncomment BOTH lines, open a new shell, type `zprof` to see where time goes.
# zmodload zsh/zprof

# ── Runtime dirs ──────────────────────────────────────────────────────────────
# These must exist before anything writes to them (history, compdump, cache).
# mkdir -p is idempotent — safe to call every time.
mkdir -p \
  "$XDG_CACHE_HOME/zsh" \
  "$XDG_STATE_HOME/zsh" \
  "$XDG_DATA_HOME/zsh"  \
  "$ANTIDOTE_HOME"

# ══════════════════════════════════════════════════════════════════════════════
# § 1  COMPLETION SYSTEM
# ══════════════════════════════════════════════════════════════════════════════
#
# When you type `git che<Tab>`, ZSH runs a completion function called `_git`.
# That function lives somewhere in a list of directories called $fpath.
# `compinit` scans $fpath, reads all those functions, and registers them.
#
# The problem: scanning all of $fpath on every shell start is slow.
# The fix: compinit writes a compiled cache file (.zcompdump). On subsequent
# starts it just sources the cache — much faster. We only force a rescan once
# every 20 hours (or when the cache is missing).
#
# ORDER MATTERS:
#   1. Add extra dirs to $fpath FIRST (so compinit finds them)
#   2. Run compinit
#   3. Load plugins that add completions (antidote handles this)
#   4. Apply zstyle completion config

# Add Homebrew completions to fpath (macOS only)
# Homebrew installs shell completions to $HOMEBREW_PREFIX/share/zsh/site-functions
# They won't work unless this dir is in $fpath before compinit runs.
if [[ "$OSTYPE" == darwin* && -n "${HOMEBREW_PREFIX-}" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit

# Smart cache: only rescan if the compdump is older than 20 hours.
# The glob qualifier (N) = null glob (no error if no match)
# (mh-20) = modified less than 20 hours ago
if [[ -n ${ZSH_COMPDUMP}(#qNmh-20) ]]; then
  compinit -C -d "$ZSH_COMPDUMP"   # -C = skip security check, use cache
else
  compinit -d "$ZSH_COMPDUMP"      # full rescan, rewrite cache
  touch "$ZSH_COMPDUMP"            # reset 20hr timer
fi

# ── Completion styling (zstyle) ────────────────────────────────────────────
#
# zstyle is ZSH's universal config mechanism. The pattern ':completion:*'
# matches all completion contexts. Each line says:
#   "in this context, set this option to this value"
#
# Think of it as CSS for the shell. The specificity works the same way —
# more specific patterns override less specific ones.

# Arrow-key navigable menu instead of flat list
zstyle ':completion:*' menu select

# Case-insensitive matching, then partial-word, then substring
# Each space-separated item is tried in order until something matches
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-z}={A-Z}' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Colorize completion menu using LS_COLORS (set by vivid below)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Show completion category headers (Files, Commands, Options, etc.)
zstyle ':completion:*:descriptions' format '%F{#cba6f7}▸ %d%f'
zstyle ':completion:*:warnings'     format '%F{#f38ba8}✗ no matches: %d%f'
zstyle ':completion:*:corrections'  format '%F{#a6e3a1}✓ %d (errors: %e)%f'
zstyle ':completion:*:messages'     format '%F{#89b4fa}%d%f'

# Group results by type with a blank line between groups
zstyle ':completion:*' group-name ''
zstyle ':completion:*' separate-sections true

# Don't insert a trailing space after completing a word that ends with /
zstyle ':completion:*' squeeze-slashes true

# Cache completions (speeds up slow completions like docker, kubectl)
zstyle ':completion::complete:*' use-cache yes
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# kill / ps: colorize PID column and always show the list
zstyle ':completion:*:*:kill:*:processes' list-colors \
  '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;38;5;196=0=01;38;5;33'
zstyle ':completion:*:kill:*' force-list always

# ssh/scp: pull hosts from ~/.ssh/known_hosts and ~/.ssh/config
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order \
  'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip *'
zstyle ':completion:*:(scp|rsync):*' group-order \
  files all-files hosts-domain hosts-host hosts-ipaddr

# Directory completion: trailing slash on dirs, colors
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# ══════════════════════════════════════════════════════════════════════════════
# § 2  ANTIDOTE — plugin manager
# ══════════════════════════════════════════════════════════════════════════════
#
# A plugin manager's job: download ZSH plugins from GitHub and make sure they
# get sourced every time your shell starts.
#
# The options in 2026:
#
#   Oh-My-Zsh   — huge framework, 300+ plugins, very slow, opinions baked in.
#                 Great for beginners. We don't need the baggage.
#
#   Zinit       — powerful, turbo/lazy loading, but complex config syntax.
#                 Has had maintainer drama, forks everywhere.
#
#   Antidote    — spiritual successor to antibody. It reads a plain text file
#                 (.zsh_plugins.txt), downloads plugins, then COMPILES them
#                 into a single static .zsh_plugins.zsh file.
#
# WHY ANTIDOTE WINS for our use case:
#   • Plugin list is a plain text file → easy to read, diff, review in git
#   • The compiled output is just `source` statements → zero overhead
#   • After first run: no network calls, no parsing, just one file sourced
#   • Works identically on macOS and Linux
#   • You can see exactly what it's doing (no magic)
#
# HOW IT WORKS:
#   1. First run: antidote reads .zsh_plugins.txt, clones each repo into
#      $ANTIDOTE_HOME, then writes a .zsh_plugins.zsh with source lines
#   2. Every subsequent run: just `source .zsh_plugins.zsh` — instant
#   3. When you add a plugin to .zsh_plugins.txt, the next shell start
#      detects the .txt is newer than .zsh and recompiles automatically

_antidote_home="${ANTIDOTE_HOME:-$XDG_DATA_HOME/antidote}"
_antidote_bin="$_antidote_home/antidote.zsh"
_plugins_txt="$ZDOTDIR/.zsh_plugins.txt"
_plugins_zsh="$ZDOTDIR/.zsh_plugins.zsh"

# Auto-bootstrap: clone antidote itself if this is a fresh machine
if [[ ! -f "$_antidote_bin" ]]; then
  print -P "%F{#89b4fa}[antidote]%f first run — cloning..."
  git clone --depth=1 --quiet https://github.com/mattmc3/antidote.git "$_antidote_home"
  print -P "%F{#a6e3a1}[antidote]%f installed ✓"
fi

source "$_antidote_bin"

# Recompile if: plugin list is newer than compiled file, or compiled file missing
if [[ ! -f "$_plugins_zsh" || "$_plugins_txt" -nt "$_plugins_zsh" ]]; then
  print -P "%F{#89b4fa}[antidote]%f plugin list changed — bundling..."
  antidote bundle <"$_plugins_txt" >"$_plugins_zsh"
  print -P "%F{#a6e3a1}[antidote]%f bundle ready ✓"
fi

source "$_plugins_zsh"
unset _antidote_home _antidote_bin _plugins_txt _plugins_zsh

# ══════════════════════════════════════════════════════════════════════════════
# § 3  HISTORY
# ══════════════════════════════════════════════════════════════════════════════
#
# ZSH history has two sizes:
#
#   HISTSIZE   = how many lines ZSH keeps in RAM during the session
#   SAVEHIST   = how many lines get written to $HISTFILE when you exit
#
# If SAVEHIST > HISTSIZE, extra lines get trimmed on write. So set them equal
# or SAVEHIST slightly smaller. 100k is plenty — it's only ~10MB of text.
#
# The setopt flags control deduplication and sharing:
#   SHARE_HISTORY     → all open shells share one live history list
#                        (new command in tab A appears in tab B's Ctrl-R)
#   EXTENDED_HISTORY  → each entry stores ": timestamp:duration;command"
#                        lets you see when you ran something

HISTSIZE=200000
SAVEHIST=200000

setopt HIST_IGNORE_DUPS      # skip recording if same as the immediately previous line
setopt HIST_IGNORE_ALL_DUPS  # delete older duplicate anywhere in history
setopt HIST_IGNORE_SPACE     # lines prefixed with a space are not saved (private commands)
setopt HIST_SAVE_NO_DUPS     # no duplicates in the file either
setopt HIST_REDUCE_BLANKS    # normalize whitespace before storing
setopt HIST_VERIFY           # show the !! expansion before running it
setopt SHARE_HISTORY         # live-share history across all shells
setopt EXTENDED_HISTORY      # prepend timestamp + duration to each entry

# ══════════════════════════════════════════════════════════════════════════════
# § 4  SHELL OPTIONS
# ══════════════════════════════════════════════════════════════════════════════
#
# ZSH has hundreds of options. These are the ones that genuinely change your
# daily workflow. Every one is explained.

# Navigation
setopt AUTO_CD          # type a directory name alone → cd into it (saves typing `cd`)
setopt AUTO_PUSHD       # every cd pushes the old dir onto a stack (access with `d` or `1`-`9`)
setopt PUSHD_IGNORE_DUPS # don't push the same dir twice onto the stack
setopt PUSHD_SILENT     # don't print the stack after every cd

# Globbing (pattern matching)
setopt GLOB_DOTS        # ls * matches dotfiles too (no need for ls .* separately)
setopt EXTENDED_GLOB    # unlocks: ^pattern (negate), (#i) (case-insensitive), **/ (recursive)
setopt NULL_GLOB        # if a glob matches nothing, remove it instead of erroring

# Quality of life
setopt NO_BEEP          # silence the terminal bell
setopt INTERACTIVE_COMMENTS  # allows `# comments` in the interactive shell
setopt MULTIOS          # `cmd > file1 > file2` — write to both files simultaneously
setopt LONG_LIST_JOBS   # show PID + status in long format when jobs are backgrounded
setopt NOTIFY           # report job status immediately, not just before next prompt
setopt RC_QUOTES        # 'it''s' → "it's" inside single-quoted strings

# ══════════════════════════════════════════════════════════════════════════════
# § 5  VI MODE
# ══════════════════════════════════════════════════════════════════════════════
#
# Your shell prompt is a tiny text editor. By default it uses "emacs mode":
# Ctrl-A = start of line, Ctrl-E = end of line, etc.
#
# Vi mode makes the prompt behave like Vim:
#   Insert mode (default) → type normally
#   Esc                   → normal mode: hjkl navigation, ciw, da", etc.
#   v (in normal mode)    → open current command in $EDITOR
#
# WHY jeffreytse/zsh-vi-mode instead of the built-in `bindkey -v`?
#
# The built-in vi mode is minimal and breaks things:
#   • It breaks fzf's Ctrl-R / Ctrl-T bindings
#   • No cursor shape changes (you can't tell which mode you're in)
#   • No text objects (ciw, da", etc.)
#   • Slow ESC response
#
# zsh-vi-mode fixes all of that. It provides a hook `zvm_after_init()`
# that fires AFTER the plugin sets up its own keymaps, so we use it to
# re-apply fzf bindings that would otherwise get clobbered.

# Must be set BEFORE the plugin loads (these are read at init time)
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT       # start every line in insert mode
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk          # jk exits insert mode (faster than ESC)

# Cursor shapes — works in Alacritty, Kitty, WezTerm, iTerm2
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM        # | beam in insert
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK       # █ block in normal
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK       # █ block in visual
ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_BLOCK  # █ block in visual-line
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE   # _ underline in operator-pending

# Disable the plugin's own surround — we use a dedicated plugin instead
ZVM_PLUGIN_SURROUND_BINDKEY=s-prefix

# This hook runs AFTER zsh-vi-mode finishes its own init.
# We use it to restore fzf bindings that zsh-vi-mode overwrites,
# and to set up history-substring-search bindings in both keymaps.
zvm_after_init() {
  # ── Restore fzf bindings ────────────────────────────────────────────────
  # zsh-vi-mode resets the keymap. fzf installs Ctrl-R/T/Alt-C into the
  # default keymap. We re-source fzf's key-bindings script after vi-mode
  # has finished so they survive.
  if [[ "$OSTYPE" == darwin* ]]; then
    local _fzf_base="$HOMEBREW_PREFIX/opt/fzf"
  else
    local _fzf_base="/usr/share/doc/fzf"
  fi
  [[ -f "$_fzf_base/shell/key-bindings.zsh" ]] && source "$_fzf_base/shell/key-bindings.zsh"
  [[ -f "$_fzf_base/shell/completion.zsh"   ]] && source "$_fzf_base/shell/completion.zsh"

  # ── history-substring-search bindings ───────────────────────────────────
  # In insert mode: ↑/↓ arrows + Ctrl-P/N
  bindkey '^[[A'  history-substring-search-up    # ↑
  bindkey '^[[B'  history-substring-search-down  # ↓
  bindkey '^P'    history-substring-search-up
  bindkey '^N'    history-substring-search-down

  # In vi normal mode: j/k (Vim-style history nav)
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down

  # ── Extra insert-mode bindings ──────────────────────────────────────────
  bindkey '^ '  autosuggest-accept              # Ctrl+Space = accept ghost text
  bindkey '^F'  autosuggest-accept              # Ctrl+F = accept (like fish)
  bindkey '^E'  end-of-line                     # Ctrl+E = end of line (emacs compat)
  bindkey '^A'  beginning-of-line               # Ctrl+A = start of line
  bindkey '^K'  kill-line                       # Ctrl+K = delete to end
  bindkey '^U'  backward-kill-line              # Ctrl+U = delete to start
  bindkey '^[[H'    beginning-of-line           # Home key
  bindkey '^[[F'    end-of-line                 # End key
  bindkey '^[[3~'   delete-char                 # Delete key
  bindkey '^[[1;5C' forward-word                # Ctrl+Right = forward word
  bindkey '^[[1;5D' backward-word               # Ctrl+Left = backward word
  bindkey '^[[3;5~' kill-word                   # Ctrl+Delete = delete next word
  bindkey '^H'      backward-kill-word          # Ctrl+Backspace = delete prev word
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  PLUGIN CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
# Plugins are already LOADED by antidote above.
# These variables/zstyles CONFIGURE their behaviour.
# They must come after antidote sources the plugins.

# ── zsh-autosuggestions ────────────────────────────────────────────────────
#
# Autosuggestions watches what you type and shows a "ghost" completion
# in grey. It has two strategies:
#   history    → finds the most recent history entry that starts with what you typed
#   completion → runs the completion engine to find possible expansions
# We try history first; if nothing matches, fall back to completion.
#
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30       # don't suggest on very long commands
ZSH_AUTOSUGGEST_USE_ASYNC=1             # fetch suggestion in background (no lag)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1         # don't rebind widgets on every precmd (faster)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"  # Catppuccin: Surface 2 (subtle grey)

# ── fast-syntax-highlighting ───────────────────────────────────────────────
#
# As you type, commands get colored:
#   Green  = valid command found in PATH
#   Red    = command not found
#   Blue   = built-in (cd, echo, alias)
#   Yellow = string / argument
#
# fast-syntax-highlighting (F-Sy-H) is faster than zsh-syntax-highlighting
# and has more features (bracket highlighting, cursor-aware coloring).
# We theme it to Catppuccin Mocha colors.
#
typeset -A FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[default]='fg=#cdd6f4'           # Text
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8'     # Red — unknown command
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=#cba6f7'     # Mauve — if/for/while
FAST_HIGHLIGHT_STYLES[command]='fg=#a6e3a1'           # Green — valid command
FAST_HIGHLIGHT_STYLES[builtin]='fg=#89dceb'           # Sky — cd, echo, etc.
FAST_HIGHLIGHT_STYLES[function]='fg=#a6e3a1'          # Green — shell function
FAST_HIGHLIGHT_STYLES[alias]='fg=#a6e3a1,bold'        # Green bold — alias
FAST_HIGHLIGHT_STYLES[path]='fg=#cdd6f4,underline'    # Text underline — file path
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#a6e3a1'  # Green
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#a6e3a1'  # Green
FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#f9e2af'  # Yellow
FAST_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#fab387'    # Peach
FAST_HIGHLIGHT_STYLES[assign]='fg=#f9e2af'            # Yellow — VAR=val
FAST_HIGHLIGHT_STYLES[redirection]='fg=#f38ba8,bold'  # Red bold — > >> |
FAST_HIGHLIGHT_STYLES[comment]='fg=#6c7086,italic'    # Overlay — # comment
FAST_HIGHLIGHT_STYLES[globbing]='fg=#f5c2e7'          # Pink — * ? []
FAST_HIGHLIGHT_STYLES[history-expansion]='fg=#f9e2af,bold'  # Yellow — !!
FAST_HIGHLIGHT_STYLES[named-fd]='none'
FAST_HIGHLIGHT_STYLES[numeric-fd]='none'
FAST_HIGHLIGHT_STYLES[variable]='fg=#89b4fa'          # Blue — $VAR

# ── history-substring-search ───────────────────────────────────────────────
#
# When you press ↑, instead of going to the previous command, ZSH
# searches history for the most recent command that CONTAINS what you've
# already typed. So if you type `docker` then press ↑, you only cycle through
# commands that included `docker` — not your entire history.
#
# The match is highlighted. Green = found, red = not found.
#
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#313244,fg=#a6e3a1,bold'    # Surface1 + Green
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#313244,fg=#f38ba8,bold' # Surface1 + Red
HISTORY_SUBSTRING_SEARCH_FUZZY=false    # exact match (fuzzy is noisy for long commands)
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true  # skip duplicates while cycling

# ── fzf-tab ────────────────────────────────────────────────────────────────
#
# fzf-tab intercepts the Tab key and instead of showing ZSH's boring
# completion menu, it opens fzf. You can fuzzy-search the completions AND get
# a live preview panel on the right showing file contents, git diffs, etc.
#
# The zstyle pattern ':fzf-tab:complete:COMMAND:CONTEXT' lets you give
# different previews to different commands.
#

# Use , and . to switch between completion groups (Files / Commands / Options)
zstyle ':fzf-tab:*' switch-group ',' '.'

# Continuous triggering: press Tab again to filter inside fzf
zstyle ':fzf-tab:*' continuous-trigger 'tab'

# Base fzf flags for all completions
zstyle ':fzf-tab:*' fzf-flags \
  --height=60% \
  --layout=reverse \
  --border=rounded \
  --info=inline

# ── Per-command previews ────────────────────────────────────────────────────
# $realpath = the actual path of the completion candidate
# $word     = the raw completion word (for git, etc.)

# cd, z: show directory tree
zstyle ':fzf-tab:complete:(cd|z|zi|zoxide):*' \
  fzf-preview 'eza --icons=always --tree --level=2 --color=always --git $realpath 2>/dev/null'

# Files (cp, mv, rm, cat, bat, nvim…): show file content
zstyle ':fzf-tab:complete:*:*' \
  fzf-preview 'bat --color=always --style=numbers,changes --line-range=:80 $realpath 2>/dev/null || eza --icons=always --color=always $realpath 2>/dev/null'

# nvim: file preview
zstyle ':fzf-tab:complete:nvim:*' \
  fzf-preview 'bat --color=always --style=numbers --line-range=:60 $realpath 2>/dev/null'

# git add / diff / restore: show the diff
zstyle ':fzf-tab:complete:git-(add|diff|restore|checkout):*' \
  fzf-preview 'git diff --color=always -- $word 2>/dev/null | head -80'

# git log: show commit details
zstyle ':fzf-tab:complete:git-log:*' \
  fzf-preview 'git show --stat --color=always $word'

# git checkout (branches): show recent commits on that branch
zstyle ':fzf-tab:complete:git-checkout:*' \
  fzf-preview 'git log --oneline --color=always -10 $word 2>/dev/null'

# kill: show process details
zstyle ':fzf-tab:complete:kill:argument-rest' \
  fzf-preview 'ps -p $word -o pid,ppid,%cpu,%mem,etime,cmd --no-header 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' \
  fzf-flags '--preview-window=down:4:wrap'

# docker ps: show container details
zstyle ':fzf-tab:complete:docker-(start|stop|rm|logs|exec):*' \
  fzf-preview 'docker inspect --format="{{json .}}" $word 2>/dev/null | python3 -m json.tool'

# brew: show package info
zstyle ':fzf-tab:complete:brew-(install|uninstall|info):*' \
  fzf-preview 'brew info $word 2>/dev/null'

# ── autopair ───────────────────────────────────────────────────────────────
# Matches: () [] {} "" '' `` — type opening char, get both, cursor inside
# Works correctly with backspace (deletes both if pair is empty)
AUTOPAIR_INHIBIT_INIT=0

# ── zsh-system-clipboard ───────────────────────────────────────────────────
#
# In vi normal mode, `y` (yank) and `d` (delete) write to the system
# clipboard, not just ZSH's internal kill ring. So you can yank a command in
# the shell and paste it in another app, and vice versa.
#
# Ctrl-O (insert mode): copies the entire current command line to clipboard.
# Works automatically on macOS (pbcopy) and Linux (xclip/wl-copy).

# ══════════════════════════════════════════════════════════════════════════════
# § 7  COLORS
# ══════════════════════════════════════════════════════════════════════════════
#
# Programs check the LS_COLORS environment variable to know what color to
# assign to each file type. The format is key=value pairs:
#   di=34    → directories in blue (ANSI color 34)
#   ln=36    → symlinks in cyan
#   ex=32    → executables in green
#
# `vivid` is a tool that generates LS_COLORS strings from theme files.
# It ships with a Catppuccin Mocha theme — much more complete than hand-writing
# LS_COLORS yourself (covers 200+ file types and extensions).
#
# eza reads EZA_COLORS on top of LS_COLORS, using the same syntax but with
# additional keys for its own columns (permissions, git status, timestamps…).

# ── LS_COLORS via vivid (Catppuccin Mocha) ────────────────────────────────
if command -v vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate catppuccin-mocha 2>/dev/null)"
else
  # Fallback: a hand-crafted minimal Catppuccin-ish palette
  # 256-color codes from the Catppuccin Mocha palette
  export LS_COLORS=\
"rs=0:di=38;5;110:ln=38;5;116:mh=00:pi=38;5;220:so=38;5;141:"\
"do=38;5;141:bd=38;5;220:cd=38;5;220:or=38;5;203:mi=00:"\
"su=38;5;203:sg=38;5;220:ca=38;5;220:tw=38;5;110:ow=38;5;110:"\
"st=38;5;110:ex=38;5;114:"\
"*.tar=38;5;203:*.tgz=38;5;203:*.zip=38;5;203:*.gz=38;5;203:"\
"*.bz2=38;5;203:*.7z=38;5;203:*.rar=38;5;203:"\
"*.jpg=38;5;141:*.jpeg=38;5;141:*.png=38;5;141:*.gif=38;5;141:"\
"*.svg=38;5;141:*.webp=38;5;141:*.mp4=38;5;141:*.mov=38;5;141:"\
"*.mp3=38;5;141:*.flac=38;5;141:*.wav=38;5;141:"\
"*.pdf=38;5;203:*.doc=38;5;110:*.docx=38;5;110:"\
"*.ts=38;5;114:*.tsx=38;5;114:*.js=38;5;220:*.jsx=38;5;220:"\
"*.json=38;5;220:*.yaml=38;5;220:*.yml=38;5;220:*.toml=38;5;220:"\
"*.md=38;5;110:*.sh=38;5;114:*.zsh=38;5;114:*.py=38;5;114:"
fi

# ── EZA_COLORS ─────────────────────────────────────────────────────────────
#
# eza extends LS_COLORS with its own keys:
#   uu  = user column when it's YOUR user  (cyan)
#   un  = user column when it's someone else's
#   gu  = group column — your primary group
#   gn  = group column — different group
#   sn  = file size number
#   sb  = file size unit (K, M, G)
#   da  = date/time column
#   ga  = git Added     (shown in --git mode)
#   gm  = git Modified
#   gd  = git Deleted
#   gr  = git Renamed
#   gc  = git conflicted
#   hd  = table header row
#   lp  = symlink path (the → target)
#   xx  = "unimportant" permissions bits
#   ur/uw/ux/ue = user  read/write/exec/extended-exec permission bits
#   gr/gw/gx    = group read/write/exec
#   tr/tw/tx    = other read/write/exec
#
# ANSI 256-color codes that match Catppuccin Mocha:
#   110 = Blue (Catppuccin #89b4fa rounded)
#   116 = Teal (#94e2d5)
#   141 = Mauve (#cba6f7)
#   114 = Green (#a6e3a1)
#   203 = Red (#f38ba8)
#   220 = Yellow (#f9e2af)
#   216 = Peach (#fab387)
#   108 = Overlay2 (#9399b2 approx)

export EZA_COLORS="\
uu=38;5;116:\
un=38;5;108:\
gu=38;5;116:\
gn=38;5;108:\
sn=38;5;114:\
sb=38;5;108:\
da=38;5;110:\
ga=38;5;114:\
gm=38;5;220:\
gd=38;5;203:\
gr=38;5;116:\
gc=38;5;203:\
hd=38;5;141;1:\
lp=38;5;116:\
xx=38;5;108:\
ur=38;5;220:\
uw=38;5;203:\
ux=38;5;114:\
ue=38;5;114:\
gw=38;5;203:\
gx=38;5;114:\
tw=38;5;203:\
tx=38;5;114:"

# EZA_ICONS_AUTO: show icons without needing --icons flag every time
export EZA_ICONS_AUTO=1

# ── GCC / compiler colors ──────────────────────────────────────────────────
export GCC_COLORS='error=01;38;5;203:warning=38;5;220:note=38;5;110:caret=38;5;114:locus=01:quote=01'

# ── grep colors ────────────────────────────────────────────────────────────
export GREP_COLORS="ms=38;5;203:mc=38;5;203:sl=:cx=:fn=38;5;110:ln=38;5;114:bn=38;5;116:se=38;5;108"

# ══════════════════════════════════════════════════════════════════════════════
# § 8  TOOLS INIT
# ══════════════════════════════════════════════════════════════════════════════

# ── Starship prompt ─────────────────────────────────────────────────────────
#
# Starship is a cross-shell prompt written in Rust. It reads
# ~/.config/starship.toml. Because the config file is shared, your prompt
# looks IDENTICAL in ZSH, Fish, and any other shell you use.
# `starship init zsh` outputs a few lines of ZSH code that hook into
# the precmd/preexec functions to update the prompt.
#
command -v starship &>/dev/null && eval "$(starship init zsh)"

# ── zoxide ──────────────────────────────────────────────────────────────────
#
# zoxide is a replacement for `cd` that learns from your habits.
# It tracks every directory you visit, weighted by how often and how recently
# you visited it (called "frecency" = frequency + recency).
#
# `z foo`     → jump to the most frecent dir matching "foo"
# `z foo bar` → matching both "foo" and "bar" in the path
# `zi`        → opens fzf to fuzzy-pick from your history
#
# `z foo`  → jump, `zi` → fzf picker
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── fnm (Fast Node Manager) ─────────────────────────────────────────────────
# Auto-switches node version when entering a dir with .nvmrc / .node-version
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"

# ══════════════════════════════════════════════════════════════════════════════
# § 9  MODULAR CONFIGS
# ══════════════════════════════════════════════════════════════════════════════
#
# Instead of one massive .zshrc, we split concerns:
#   conf.d/aliases.zsh     → all alias definitions
#   conf.d/functions.zsh   → shell functions (too complex for aliases)
#   conf.d/completions.zsh → tool-generated completions, cached
#   conf.d/git.zsh         → git-specific config and helpers
#
# The (N) glob qualifier = "null glob" — if the pattern matches nothing,
# expand to empty instead of an error. Safe even if conf.d/ is empty.
#
for _f in "$ZDOTDIR/conf.d/"*.zsh(N); do
  source "$_f"
done
unset _f

# ══════════════════════════════════════════════════════════════════════════════
# § 10  LOCAL OVERRIDES
# ══════════════════════════════════════════════════════════════════════════════
# Machine-specific config that shouldn't be in git.
# Examples: work API tokens, company-specific PATH entries, local tool paths.
# This file is listed in .gitignore.
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# zprof  # ← uncomment to print startup profile (pair with zmodload at top)
