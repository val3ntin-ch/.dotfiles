# $ZDOTDIR/conf.d/aliases.zsh
# ══════════════════════════════════════════════════════════════════════════════
# what is an alias?
#
# An alias is a name that expands to a longer string before ZSH executes it.
# `alias gs="git status -sb"` means every time you type `gs`, ZSH replaces it
# with `git status -sb` before running anything. It's pure text substitution.
#
# Rules:
#   • Aliases are for SHORT substitutions. If you need logic (if/loops/args)
#     → use a function (functions.zsh).
#   • `command -v foo &>/dev/null` checks if foo exists before aliasing it.
#     This makes the config safe on machines where a tool isn't installed yet.
#   • Global aliases (alias -g) expand anywhere on the line, not just position 0.
#     `alias -g NUL=">/dev/null 2>&1"` lets you write `cmd NUL` anywhere.
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
# EZA — modern ls replacement (Rust, maintained fork of exa)
# ══════════════════════════════════════════════════════════════════════════════
#
# why eza instead of ls?
#
# GNU `ls` was written in the 1970s. It shows filenames and that's it.
# eza shows: icons, git status per file, column headers, human sizes,
# symlink targets, extended attributes, color-coded permissions.
#
# Flag reference:
#   --icons=always      → always show Nerd Font icons (no env check needed)
#   --group-directories-first → dirs at top, then files
#   --color=always      → force colors even when piped
#   -l                  → long format (permissions, size, date, name)
#   -a / -A             → show hidden files (-A excludes . and ..)
#   --git               → show git status column (M, A, D, ?, …)
#   --git-ignore        → hide files ignored by .gitignore
#   --header            → print column headers
#   --time-style=relative → show "3 days ago" instead of "2024-01-15"
#   --total-size        → for dirs, show total size of contents (not just inode)
#   --smart-group       → only show group if it differs from the owner
#   --tree              → recursive tree view
#   --level=N           → tree depth limit

if command -v eza &>/dev/null; then
  alias ls='eza --group-directories-first --icons'
  alias ll='eza -l -g --icons'
  alias la='eza -a --icons'
  alias lla='eza -la -g --icons'
  alias llt='eza -la -g --icons --tree --level=2'
else
  # macOS BSD ls fallback
  alias ls='ls -p -G'
  alias la='ls -A'
  alias ll='ls -l'
  alias lla='ls -lA'
fi

# ══════════════════════════════════════════════════════════════════════════════
# BAT — cat with syntax highlighting, line numbers, git integration
# ══════════════════════════════════════════════════════════════════════════════
#
# why bat instead of cat?
#
# `cat` just dumps bytes to stdout. bat adds:
#   • Syntax highlighting for 200+ languages
#   • Line numbers
#   • Git change markers in the gutter (lines added/modified/deleted)
#   • Paging when the file is long (like less, but with syntax highlighting)
#   • Unicode and binary detection
#
# --paging=never: don't invoke less — just print (same behavior as cat)
# --style=numbers,changes,header: show line numbers, git gutter, filename header
# BAT_THEME is set in .zshenv to "Catppuccin Mocha"

if command -v bat &>/dev/null; then
  alias cat='bat --paging=never --style=plain'
  alias catn='bat --paging=never --style=numbers,changes'   # with line numbers
  alias catp='bat --style=numbers,changes,header'           # with paging
  alias batdiff='bat --diff'                                # show only changed lines
fi

# ══════════════════════════════════════════════════════════════════════════════
# NAVIGATION
# ══════════════════════════════════════════════════════════════════════════════

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'    # go back to previous dir (- is special syntax)

# Directory stack — enabled by AUTO_PUSHD in .zshrc
# Every cd automatically pushes to the stack. `d` shows the stack.
# `1` through `9` jump to that position in the stack.
alias d='dirs -v | head -10'
for i in {1..9}; do alias "$i"="cd +$i"; done; unset i

# ══════════════════════════════════════════════════════════════════════════════
# EDITOR
# ══════════════════════════════════════════════════════════════════════════════

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias nv='nvim'

# Open with sudo but preserve your nvim config
alias svim='sudo -E nvim'

# ══════════════════════════════════════════════════════════════════════════════
# GIT — the full 2026 workflow
# ══════════════════════════════════════════════════════════════════════════════
#
# alias strategy for git:
#
# Short 2-letter aliases for the commands you run dozens of times a day.
# Longer aliases for commands that are important but less frequent.
# Never alias something that has destructive defaults without making
# the danger obvious in the alias name (e.g. `grhh` for --hard reset).
#
# 2026 workflow notes:
#   • `git switch` / `git restore` replace `git checkout` for branch and file ops
#     (checkout does too many things). Both are now stable since Git 2.23+.
#   • `--force-with-lease` instead of `--force` — checks nobody else has pushed
#     before you overwrite. Safe force push.
#   • `git log --oneline --graph` gives you the visual branch history.
#   • Worktrees: work on two branches simultaneously without stashing.

alias g='git'

# ── Status ────────────────────────────────────────────────────────────────
alias gs='git status -sb'                         # short status with branch info
alias gss='git status'                            # full status

# ── Add / Stage ───────────────────────────────────────────────────────────
alias ga='git add'
alias gaa='git add -A'                            # add everything
alias gap='git add -p'                            # interactive patch — add hunks
alias gai='git add -i'                            # interactive add menu

# ── Commit ────────────────────────────────────────────────────────────────
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'                    # amend (opens editor)
alias gcane='git commit --amend --no-edit'        # amend without changing message
alias gcem='git commit --allow-empty -m'          # empty commit (trigger CI etc.)
alias gcf='git commit --fixup'                    # create fixup! commit for rebase --autosquash

# ── Branch (modern: switch/restore over checkout) ─────────────────────────
# `git switch` = change branches (what `git checkout <branch>` used to do)
# `git restore` = undo file changes (what `git checkout -- <file>` used to do)
# Separating them makes intent explicit.
alias gsw='git switch'                            # switch branch
alias gswc='git switch -c'                        # create + switch
alias gswd='git switch -d'                        # switch to detached HEAD
alias gswm='git switch $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|origin/||" || echo main)'  # → main
alias gr='git restore'                            # restore file (discard changes)
alias grs='git restore --staged'                  # unstage file

# Keep gco as muscle memory alias for checkout (still works fine)
alias gco='git checkout'
alias gcob='git checkout -b'                      # legacy: create+switch

# ── Diff ──────────────────────────────────────────────────────────────────
alias gd='git diff'                               # unstaged changes
alias gds='git diff --staged'                     # staged changes (what you'll commit)
alias gdc='git diff --cached'                     # same as staged
alias gdt='git diff --stat'                       # summary: files + insertions/deletions
alias gdw='git diff --word-diff'                  # word-level diff (great for prose)
alias gdo='git diff origin/$(git branch --show-current)'  # vs remote

# ── Log ───────────────────────────────────────────────────────────────────
# The big one: visual graph, all branches, compact
alias glog='git log --oneline --graph --decorate --all'
# With author + date
alias gloga='git log --oneline --graph --decorate --all \
  --format="%C(auto)%h%d %s %C(blue)%an %C(dim)%ar"'
# Last N commits (default 10)
alias gln='git log --oneline -10'
# Full diff of recent commits
alias glp='git log -p --follow'
# Who changed this file
alias gblame='git log --follow -p --'
# Pretty: show stats
alias gll='git log --stat --oneline'

# ── Push / Pull ───────────────────────────────────────────────────────────
alias gp='git push'
alias gpf='git push --force-with-lease'           # safe force (checks remote state)
alias gpff='git push --force'                     # DANGER: unconditional force
alias gpu='git push -u origin HEAD'               # push new branch + set upstream
alias gpt='git push --tags'                       # push tags
alias gl='git pull'
alias glr='git pull --rebase'                     # pull + rebase instead of merge
alias gla='git pull --all'                        # fetch + merge all remotes

# ── Fetch ─────────────────────────────────────────────────────────────────
alias gf='git fetch'
alias gfa='git fetch --all --prune'               # fetch + delete stale remote refs
alias gfp='git fetch --prune'                     # delete stale remote refs for origin

# ── Rebase ────────────────────────────────────────────────────────────────
alias grb='git rebase'
alias grbi='git rebase -i'                        # interactive rebase
alias grbia='git rebase -i --autosquash'          # with fixup! squashing
alias grbo='git rebase -i origin/$(git branch --show-current)'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias grbs='git rebase --skip'

# ── Stash ─────────────────────────────────────────────────────────────────
# stash = temporary shelf for work-in-progress
alias gst='git stash'
alias gsta='git stash push -u'                    # stash including untracked
alias gstp='git stash pop'                        # apply + drop stash
alias gstl='git stash list'
alias gstd='git stash drop'
alias gstb='git stash branch'                     # create branch from stash
alias gsts='git stash show -p'                    # show stash contents as diff

# ── Branch management ─────────────────────────────────────────────────────
alias gbr='git branch'
alias gbra='git branch -a'                        # local + remote branches
alias gbrv='git branch -vv'                       # verbose: shows upstream + ahead/behind
alias gbrd='git branch -d'                        # delete (safe — must be merged)
alias gbrD='git branch -D'                        # force delete (DANGER)
alias gbrsort='git branch --sort=-committerdate'  # sort by most recently used
alias gbrclean='git branch --merged | grep -vE "(^\*|main|master|develop)" | xargs git branch -d'
  # ^ delete all branches that are fully merged into current branch

# ── Cherry-pick ───────────────────────────────────────────────────────────
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcpn='git cherry-pick --no-commit'          # apply changes without committing

# ── Reset ─────────────────────────────────────────────────────────────────
# DANGER territory — named to be obvious
alias grh='git reset HEAD'                        # unstage all
alias grhh='git reset --hard HEAD'               # HARD reset — discard all changes
alias grhs='git reset --soft HEAD~1'             # undo last commit, keep staged
alias grhm='git reset --mixed HEAD~1'            # undo last commit, keep unstaged

# ── Clean ─────────────────────────────────────────────────────────────────
alias gclean='git clean -fd'                      # delete untracked files + dirs
alias gcleanx='git clean -fdx'                    # also delete gitignored files

# ── Tags ──────────────────────────────────────────────────────────────────
alias gtag='git tag -n'                           # list tags with annotations
alias gtaga='git tag -a'                          # annotated tag (opens editor)
alias gtagd='git tag -d'                          # delete tag locally

# ── Worktrees (2026 power feature) ────────────────────────────────────────
#
# what is a git worktree?
#
# Normally, one git repo = one working directory. If you need to work on
# branch B while branch A builds, you have to stash, switch, work, switch back.
#
# Worktrees let you check out MULTIPLE BRANCHES simultaneously into different
# directories on disk — all sharing the same .git folder. So you can have:
#   ~/projects/myapp/          (main branch)
#   ~/projects/myapp-feat/     (feature/new-login branch)
# Both are live at the same time. No stashing. No switching.
#
alias gwt='git worktree'
alias gwta='git worktree add'                     # gwta ../myapp-feat feat/new-login
alias gwtl='git worktree list'
alias gwtr='git worktree remove'
alias gwtpr='git worktree prune'                  # clean up deleted worktrees

# ── Misc ──────────────────────────────────────────────────────────────────
alias gignore='git update-index --assume-unchanged'    # ignore local changes to tracked file
alias gunignore='git update-index --no-assume-unchanged'
alias gwhoami='git config user.name && git config user.email'
alias groot='cd $(git rev-parse --show-toplevel)'  # cd to repo root (use `cdg` from plugin too)
alias ghash='git rev-parse --short HEAD'           # print current commit hash
alias gurl='git remote get-url origin'             # print origin URL

# ══════════════════════════════════════════════════════════════════════════════
# TMUX
# ══════════════════════════════════════════════════════════════════════════════
#
# tmux terminology:
#   server  → background process, holds all sessions
#   session → a collection of windows (like a project workspace)
#   window  → a tab within a session
#   pane    → a split within a window

alias t='tmux'
alias ta='tmux attach -t'                         # attach to named session
alias tad='tmux attach -d -t'                     # detach others, then attach
alias tn='tmux new-session -s'                    # new named session
alias tns='tmux new-session'                      # new unnamed session
alias tl='tmux list-sessions'                     # list sessions
alias tw='tmux list-windows'                      # list windows in current session
alias tk='tmux kill-session -t'                   # kill named session
alias tka='tmux kill-server'                      # kill EVERYTHING
alias ts='tmux switch-client -t'                  # switch to session by name
alias trn='tmux rename-session'                   # rename current session
alias tpk='tmux kill-pane'                        # kill current pane
alias tsrc='tmux source-file ~/.config/tmux/tmux.conf'  # reload config

# Smart tmux attach: attach to existing or create new
alias T='tmux new-session -A -s main'             # attach to "main" or create it

# ══════════════════════════════════════════════════════════════════════════════
# NODE / PNPM
# ══════════════════════════════════════════════════════════════════════════════

alias pn='pnpm'
alias pni='pnpm install'
alias pna='pnpm add'
alias pnad='pnpm add -D'                          # add as devDependency
alias pnr='pnpm run'
alias pnd='pnpm dev'
alias pnb='pnpm build'
alias pnt='pnpm test'
alias pntw='pnpm test --watch'
alias pnl='pnpm lint'
alias pnlf='pnpm lint --fix'
alias pntc='pnpm typecheck'
alias pnx='pnpm dlx'                             # pnpm exec (like npx)
alias pnup='pnpm update --interactive --latest'  # interactive dep update
alias pnwhy='pnpm why'                            # why is this package installed?
alias pnclean='rm -rf node_modules .turbo dist && pnpm install'

# ── React Native / Expo ───────────────────────────────────────────────────
alias rni='npx react-native run-ios'
alias rna='npx react-native run-android'
alias rnios='npx react-native run-ios --simulator="iPhone 15 Pro"'
alias pods='cd ios && bundle exec pod install && cd ..'
alias rnclean='watchman watch-del-all && rm -rf node_modules ios/Pods ios/build android/build && pnpm install'
alias expo='npx expo'
alias expod='npx expo start'
alias expob='npx expo build'
alias expodc='npx expo start --clear'

# ══════════════════════════════════════════════════════════════════════════════
# RIPGREP + FD
# ══════════════════════════════════════════════════════════════════════════════
#
# why rg over grep, fd over find?
#
# rg (ripgrep):
#   • Written in Rust, 10-100x faster than grep on large codebases
#   • Respects .gitignore automatically
#   • Smart case: lowercase query = case-insensitive, mixed = case-sensitive
#   • Better output formatting (groups matches by file)
#
# fd:
#   • Written in Rust, faster than find
#   • Respects .gitignore
#   • Simpler syntax: `fd pattern` instead of `find . -name "*pattern*"`

if command -v rg &>/dev/null; then
  alias rg='rg --color=always --smart-case'       # always color, smart case
  alias rgi='rg --ignore-case'                    # force case-insensitive
  alias rgf='rg --files-with-matches'             # only print filenames
  alias rgts='rg --type=ts'                       # search only TypeScript files
  alias rgjs='rg --type=js'                       # search only JS files
fi

if command -v fd &>/dev/null; then
  alias fd='fd --color=always'
  alias fdf='fd --type f'                         # files only
  alias fdd='fd --type d'                         # dirs only
  alias fdh='fd --hidden'                         # include hidden files
fi

# ══════════════════════════════════════════════════════════════════════════════
# SYSTEM UTILITIES
# ══════════════════════════════════════════════════════════════════════════════

alias reload='exec zsh'                           # reload shell (new process, clean state)
alias reloads='source $ZDOTDIR/.zshrc'            # soft reload (in-place, keeps state)
alias path='echo $PATH | tr ":" "\n" | nl'        # print PATH, one entry per line, numbered
alias ports='lsof -i -P -n | grep LISTEN'         # show listening ports
alias myip='curl -s https://api.ipify.org && echo' # public IP

alias df='df -h'                                  # human-readable sizes
alias du='du -sh'                                 # single-dir size summary
alias dua='du -sh * | sort -h'                    # all items sorted by size

# Process
alias psa='ps aux'
alias psg='ps aux | grep'                         # psg nginx — find process

# Network
alias ping='ping -c 5'                            # limit to 5 packets by default

# Dotfiles quick access
alias dot='cd ${DOTFILES_DIR:-$HOME/.dotfiles}'
alias zrc='nvim $ZDOTDIR/.zshrc'
alias zenv='nvim $ZDOTDIR/.zshenv'
alias zalias='nvim $ZDOTDIR/conf.d/aliases.zsh'
alias zfn='nvim $ZDOTDIR/conf.d/functions.zsh'
alias zplug='nvim $ZDOTDIR/.zsh_plugins.txt'
alias zconf='nvim $ZDOTDIR'                       # open whole zsh dir in nvim

# ══════════════════════════════════════════════════════════════════════════════
# CLIPBOARD
# ══════════════════════════════════════════════════════════════════════════════
#
# why abstract the clipboard?
#
# macOS uses pbcopy/pbpaste. Linux with X11 uses xclip or xsel.
# Linux with Wayland uses wl-copy/wl-paste. By aliasing them all to `copy`/`paste`,
# your muscle memory and scripts work on every machine.
#
# Usage: `cat file.txt | copy` — copies file to clipboard
#        `paste | grep foo`    — paste clipboard into a grep
#
# (zsh-system-clipboard handles the vi-mode y/p integration separately)

if [[ "$OSTYPE" == darwin* ]]; then
  alias copy='pbcopy'
  alias paste='pbpaste'
elif command -v wl-copy &>/dev/null; then         # Wayland (modern Linux)
  alias copy='wl-copy'
  alias paste='wl-paste'
elif command -v xclip &>/dev/null; then           # X11
  alias copy='xclip -selection clipboard'
  alias paste='xclip -selection clipboard -o'
elif command -v xsel &>/dev/null; then            # X11 fallback
  alias copy='xsel --clipboard --input'
  alias paste='xsel --clipboard --output'
fi

# ══════════════════════════════════════════════════════════════════════════════
# GLOBAL ALIASES
# ══════════════════════════════════════════════════════════════════════════════
#
# global aliases expand anywhere on the command line, not just at
# position 0. So `cmd NUL` expands NUL wherever it appears.
#
# Use sparingly — they can make scripts confusing if overused.

alias -g NUL='>/dev/null 2>&1'                   # discard all output
alias -g NULL='2>/dev/null'                       # discard stderr only
alias -g G='| grep'                              # pipe to grep: cmd G pattern
alias -g GI='| grep -i'                          # case-insensitive grep
alias -g L='| less'                              # pipe to less
alias -g H='| head'                              # pipe to head
alias -g T='| tail'                              # pipe to tail
alias -g TF='| tail -f'                          # follow (like tail -f)
alias -g WC='| wc -l'                            # count lines
alias -g JSON='| python3 -m json.tool'           # pretty-print JSON
alias -g COPY='| pbcopy'                         # copy to clipboard (macOS)

# ══════════════════════════════════════════════════════════════════════════════
# PLATFORM-SPECIFIC
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$OSTYPE" == darwin* ]]; then
  alias o='open'                                  # open file/URL in default app
  alias ql='qlmanage -p 2>/dev/null'             # QuickLook preview from terminal
  alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
  alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
  alias cleanup='find . -type f -name "*.DS_Store" -delete'
  alias update='brew update && brew upgrade && brew autoremove && brew cleanup'
  alias brewdump='brew bundle dump --file="${DOTFILES_DIR:-$HOME/.dotfiles}/Brewfile" --force'  # save installed apps
  # Caffeinate: keep mac awake (optional N seconds)
  alias awake='caffeinate -d'
fi

if [[ "$OSTYPE" == linux* ]]; then
  alias o='xdg-open'
  alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
  # Copy/paste already handled above in clipboard section
fi
