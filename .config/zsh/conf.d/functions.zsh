# $ZDOTDIR/conf.d/functions.zsh
# ══════════════════════════════════════════════════════════════════════════════
# functions vs aliases:
#
# Alias:    text substitution, no arguments beyond the substituted string.
# Function: real code — can take named arguments ($1 $2), use if/loops,
#           run multiple commands, return values, use local variables.
#
# Pattern: if the logic can't fit on one line or needs $1, make it a function.
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
# DIRECTORY / NAVIGATION
# ══════════════════════════════════════════════════════════════════════════════

# mkcd — mkdir + cd in one step
# Usage: mkcd src/components/Button
# Why: you almost always want to cd into the dir you just created
mkcd() {
  [[ -z "$1" ]] && { echo "usage: mkcd <path>"; return 1 }
  mkdir -p "$1" && cd "$1"
}

# up — go up N directories
# Usage: up 3  (equivalent to cd ../../..)
up() {
  local n="${1:-1}"
  local path=""
  for (( i=0; i<n; i++ )); do path+="../"; done
  cd "$path"
}

# fcd — fuzzy cd: search all dirs with fzf, cd into selection
# Uses fd (fast) + fzf (interactive) + eza (preview)
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow \
         --exclude .git --exclude node_modules --exclude .cache \
         "${1:-.}" 2>/dev/null \
    | fzf \
        --preview='eza --icons=always --tree --level=2 --color=always {}' \
        --preview-window='right:50%' \
        --prompt='cd ❯ ')
  [[ -n "$dir" ]] && cd "$dir"
}

# ══════════════════════════════════════════════════════════════════════════════
# FILE OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════

# fe — fuzzy-find a file, open in $EDITOR
# Usage: fe (opens fzf in cwd), fe src (starts from src/)
fe() {
  local file
  file=$(fd --type f --hidden --follow \
          --exclude .git --exclude node_modules \
          "${1:-.}" 2>/dev/null \
    | fzf \
        --preview='bat --color=always --style=numbers,changes --line-range=:80 {}' \
        --preview-window='right:55%' \
        --prompt='edit ❯ ')
  [[ -n "$file" ]] && $EDITOR "$file"
}

# bak — backup a file with timestamp
# Usage: bak config.json → config.json.bak.20240115-143022
bak() {
  [[ -z "$1" ]] && { echo "usage: bak <file>"; return 1 }
  cp -v "$1" "${1}.bak.$(date +%Y%m%d-%H%M%S)"
}

# extract — universal archive extractor
# Usage: extract archive.tar.gz
extract() {
  if [[ -z "$1" ]]; then
    echo "usage: extract <archive>"
    return 1
  fi
  if [[ ! -f "$1" ]]; then
    echo "error: '$1' is not a file"
    return 1
  fi
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1"   ;;
    *.tar.gz|*.tgz)   tar xzf "$1"   ;;
    *.tar.xz|*.txz)   tar xJf "$1"   ;;
    *.tar.zst)         tar --zstd -xf "$1" ;;
    *.tar)             tar xf "$1"    ;;
    *.bz2)             bunzip2 "$1"   ;;
    *.gz)              gunzip "$1"    ;;
    *.zip)             unzip "$1"     ;;
    *.7z)              7z x "$1"      ;;
    *.rar)             unrar x "$1"   ;;
    *.Z)               uncompress "$1" ;;
    *.zst)             zstd -d "$1"   ;;
    *)  echo "unknown format: '$1'"; return 1 ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════════════
# FZF UTILITIES
# ══════════════════════════════════════════════════════════════════════════════
#
# fzf is a fuzzy finder: you pipe a list of things to it, and it
# gives you an interactive prompt to fuzzy-search + select from them. The
# selected item is printed to stdout. We combine this with other tools to build
# interactive workflows.

# fh — fuzzy history search + execute
# Different from Ctrl-R: fh shows the result, you press Enter to run it.
# Ctrl-R puts it on the command line for editing first.
fh() {
  local cmd
  cmd=$(fc -l 1 \
    | awk '{ $1=""; sub(/^ /, ""); print }' \
    | sort -u \
    | fzf --tac --no-sort \
          --preview='echo {}' \
          --preview-window='down:3:wrap' \
          --prompt='history ❯ ')
  [[ -n "$cmd" ]] && print -z "$cmd"   # put into ZSH buffer (don't run immediately)
}

# fkill — fuzzy kill process
# Shows all processes in fzf, select one (or multiple with Tab), kills them
fkill() {
  local signal="${1:--9}"
  local pids
  pids=$(ps aux \
    | fzf --header-lines=1 \
          --multi \
          --preview='echo {}' \
          --preview-window='down:3:wrap' \
          --prompt="kill ($signal) ❯ " \
    | awk '{print $2}')
  [[ -n "$pids" ]] && echo "$pids" | xargs kill "$signal" && echo "killed: $pids"
}

# rgv — ripgrep → fzf → open in nvim at the exact line
# Usage: rgv "useState" (finds all occurrences, pick one, opens nvim there)
rgv() {
  [[ -z "$1" ]] && { echo "usage: rgv <pattern> [path]"; return 1 }
  local result
  result=$(rg --line-number --no-heading --color=always --smart-case "$@" \
    | fzf --ansi \
          --delimiter=: \
          --preview='bat --color=always --style=numbers --highlight-line={2} {1}' \
          --preview-window='right:55%,+{2}-5' \
          --prompt='rg ❯ ')
  [[ -n "$result" ]] || return
  local file="${result%%:*}"
  local line="${${result#*:}%%:*}"
  nvim +"$line" "$file"
}

# ══════════════════════════════════════════════════════════════════════════════
# GIT FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# git-switch-fzf — fuzzy git branch switcher with log preview
# Shows local + remote branches, preview shows recent commits
git-switch-fzf() {
  local branch
  branch=$(git branch --all --color=always 2>/dev/null \
    | grep -v 'HEAD' \
    | sed 's|remotes/[^/]*/||' \
    | sort -u \
    | fzf --ansi \
          --preview='git log --oneline --color=always -15 {1} 2>/dev/null' \
          --preview-window='right:50%' \
          --prompt='branch ❯ ' \
    | sed 's/^[[:space:]]*//' \
    | sed 's|remotes/[^/]*/||')
  [[ -n "$branch" ]] && git switch "$branch"
}

# git-add-fzf — fuzzy interactive git add
# Shows changed files, Tab to multi-select, preview shows the diff
git-add-fzf() {
  local files
  files=$(git status --short 2>/dev/null \
    | fzf --ansi \
          --multi \
          --preview='git diff --color=always -- {2} 2>/dev/null | head -60' \
          --preview-window='right:55%' \
          --prompt='stage ❯ ' \
    | awk '{print $2}')
  [[ -n "$files" ]] && echo "$files" | xargs git add && git status -sb
}

# git-log-fzf — interactive git log browser
# Browse commits in fzf, preview shows the full diff
# Enter: open commit in nvim (via delta or bat)
git-log-fzf() {
  git log --oneline --color=always --decorate "${@:-.}" \
    | fzf --ansi --no-sort \
          --preview='git show --color=always --stat {1}' \
          --preview-window='right:55%' \
          --bind='enter:execute(git show --color=always {1} | less -R)' \
          --prompt='log ❯ '
}

# git-diff-fzf — fuzzy-pick a file from git status to diff
git-diff-fzf() {
  local file
  file=$(git status --short \
    | fzf --ansi \
          --preview='git diff --color=always -- {2}' \
          --preview-window='right:60%' \
          --prompt='diff ❯ ' \
    | awk '{print $2}')
  [[ -n "$file" ]] && git diff "$file"
}

# wip — quick "work in progress" commit
# Usage: wip (commits everything with a wip timestamp)
# Named `wip` not `gwip` to avoid collision with OMZ git plugin alias.
wip() {
  git add -A
  git commit -m "wip: $(date '+%Y-%m-%d %H:%M') [skip ci]"
}

# unwip — undo the last wip commit, keep changes staged
unwip() {
  local msg
  msg=$(git log -1 --pretty=%s)
  if [[ "$msg" == wip:* ]]; then
    git reset HEAD~1
    echo "wip commit undone, changes are staged"
  else
    echo "last commit is not a wip commit: '$msg'"
    return 1
  fi
}

# git-clone-cd — clone a repo and cd into it
# Usage: gclone https://github.com/user/repo
#        gclone user/repo  (assumes github)
git-clone-cd() {
  local url="$1"
  # Expand shorthand: user/repo → https://github.com/user/repo
  if [[ "$url" != *"://"* && "$url" != git@* ]]; then
    url="https://github.com/$url"
  fi
  local dir="${2:-$(basename "${url%.git}")}"
  git clone "$url" "$dir" && cd "$dir"
}

# pr-checkout — checkout a GitHub pull request by number
# Requires: gh CLI
pr-checkout() {
  [[ -z "$1" ]] && { echo "usage: gpr <pr-number>"; return 1 }
  gh pr checkout "$1"
}

# git-open — open current repo on GitHub in browser
git-open() {
  local url
  url=$(git remote get-url origin 2>/dev/null)
  [[ -z "$url" ]] && { echo "not a git repo or no origin"; return 1 }
  # Convert SSH to HTTPS URL
  url="${url/git@github.com:/https://github.com/}"
  url="${url%.git}"
  if [[ "$OSTYPE" == darwin* ]]; then
    open "$url"
  else
    xdg-open "$url"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TMUX FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# fal — fuzzy alias finder: fal (all), fal git, fal tmux
# Browse every defined alias in fzf, pre-filtered by argument
fal() {
  alias | sort | fzf --prompt='alias ❯ ' --query="$*" \
    --preview='echo {}' --preview-window='down:3:wrap'
}

# fts — fuzzy tmux session switcher
# Shows all sessions in fzf, preview shows windows in that session
fts() {
  local session
  session=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{window_name})' 2>/dev/null \
    | fzf --prompt='tmux ❯ ' \
          --preview='tmux list-windows -t {1}' \
          --preview-window='down:4:wrap' \
    | cut -d: -f1)
  [[ -n "$session" ]] && tmux switch-client -t "$session"
}

# tdev — spin up a structured dev session for a project
#
# what does this do?
# Creates a tmux session named after the project with a sensible layout:
#   Single window "dev": nvim left 70% + terminal right 30%
# If the session already exists, just attaches to it.
# Mirrors fish version: .config/fish/functions/tdev.fish
#
# Usage: tdev (uses cwd), tdev myproject (resolves via zoxide), tdev ./path
tdev() {
  local name root
  name="$(basename "$PWD")"
  root="$PWD"
  if [[ $# -ge 2 ]]; then
    name="$1"
    root="$2"
  elif [[ $# -eq 1 ]]; then
    if [[ -d "$1" ]]; then
      # arg is a path — use it directly
      root="$(realpath "$1")"
    else
      # resolve project path via zoxide (like `z <name>`)
      local zdir
      zdir="$(zoxide query "$1" 2>/dev/null)"
      [[ -n "$zdir" ]] && root="$zdir"
    fi
    name="$(basename "$root")"
  fi
  # tmux session names can't contain . or : (target separators)
  name="${name//./_}"

  # Create session if it doesn't exist (-d = detached, don't attach yet)
  if ! tmux has-session -t "${name}" 2>/dev/null; then
    tmux new-session -d -s "${name}" -c "$root"

    # Single window: nvim left 70% + terminal right 30%
    tmux rename-window -t "${name}:1" 'dev'
    tmux split-window -t "${name}:dev" -h -l 30% -c "$root"
    tmux select-pane -t "${name}:dev.left"
    tmux send-keys -t "${name}:dev.left" 'nvim .' Enter
  fi

  # Attach (or switch if inside tmux already)
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "${name}"
  else
    tmux attach-session -t "${name}"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# NODE / JS FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# nvmuse — read .nvmrc/.node-version and switch via fnm
nvmuse() {
  if [[ -f ".nvmrc" || -f ".node-version" ]]; then
    fnm use --install-if-missing --log-level quiet
  else
    echo "no .nvmrc / .node-version in current directory"
  fi
}

# pnscript — show package.json scripts with fzf, run selected one
pnscript() {
  [[ ! -f "package.json" ]] && { echo "no package.json in cwd"; return 1 }
  local script
  script=$(cat package.json \
    | python3 -c "import sys,json; scripts=json.load(sys.stdin).get('scripts',{}); [print(k,'\t',v) for k,v in scripts.items()]" \
    | fzf --tabstop=30 --prompt='pnpm run ❯ ' \
          --preview='echo {2..}' \
          --preview-window='down:3:wrap' \
    | awk '{print $1}')
  [[ -n "$script" ]] && pnpm run "$script"
}

# ══════════════════════════════════════════════════════════════════════════════
# NETWORK / SYSTEM
# ══════════════════════════════════════════════════════════════════════════════

# my-ip — show local + public IP
my-ip() {
  local local_ip
  if [[ "$OSTYPE" == darwin* ]]; then
    local_ip=$(ipconfig getifaddr en0 2>/dev/null \
            || ipconfig getifaddr en1 2>/dev/null \
            || echo "N/A")
  else
    local_ip=$(ip route get 1 2>/dev/null | awk '{print $7}' \
            || hostname -I | awk '{print $1}' \
            || echo "N/A")
  fi
  local public_ip
  public_ip=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "N/A")
  printf "Local:  %s\nPublic: %s\n" "$local_ip" "$public_ip"
}

# serve — quick HTTP server in current directory
# Usage: serve (port 8080), serve 3000
serve() {
  local port="${1:-8080}"
  local ip
  ip=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')
  echo "Serving on:"
  echo "  http://localhost:$port"
  echo "  http://${ip}:$port"
  python3 -m http.server "$port"
}

# ══════════════════════════════════════════════════════════════════════════════
# DOTFILES MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

# stow-pkg — stow a single dotfiles package
# Usage: stow-pkg zsh  (creates ~/.config/zsh → ~/.dotfiles/.config/zsh)
stow-pkg() {
  local pkg="$1"
  local dotdir="${DOTFILES_DIR:-$HOME/.dotfiles}"
  [[ -z "$pkg" ]] && { echo "usage: stow-pkg <package>"; return 1 }
  stow --dir="$dotdir" --target="$HOME" --restow --no-folding ".config/$pkg" \
    && echo "✓ stowed: $pkg"
}

# stow-all — restow every package in ~/.dotfiles/.config/
# Conditional packages are only stowed if their tool is installed.
stow-all() {
  local dotdir="${DOTFILES_DIR:-$HOME/.dotfiles}"
  [[ ! -d "$dotdir/.config" ]] && { echo "no .config dir in $dotdir"; return 1 }

  # Map: config folder name → binary that must exist to stow it.
  # Add any tool-specific configs here so they're skipped on machines
  # where the tool isn't installed (e.g. no alacritty on a remote server).
  local -A conditional=(
    [alacritty]=alacritty
    [kitty]=kitty
    [wezterm]=wezterm
  )

  local count=0 skipped=0
  for pkg_path in "$dotdir/.config"/*/; do
    local pkg="$(basename "$pkg_path")"

    if [[ -n "${conditional[$pkg]}" ]] && ! command -v "${conditional[$pkg]}" &>/dev/null; then
      echo "  skip  $pkg  (${conditional[$pkg]} not found)"
      (( skipped++ ))
      continue
    fi

    stow-pkg "$pkg" && (( count++ ))
  done

  echo ""
  echo "stowed $count packages, skipped $skipped"
}

# ══════════════════════════════════════════════════════════════════════════════
# MISC
# ══════════════════════════════════════════════════════════════════════════════

# cl — cd then eza
# Usage: cl src/components (cd into dir and immediately show contents)
cl() {
  cd "${1:-.}" && eza --icons=always --group-directories-first --color=always \
    -la --git --time-style=relative 2>/dev/null || ls -la
}

# mkenv — create a .env file from .env.example
mkenv() {
  local src="${1:-.env.example}"
  local dst="${2:-.env}"
  [[ ! -f "$src" ]] && { echo "no $src found"; return 1 }
  [[ -f "$dst" ]] && { echo "$dst already exists, not overwriting"; return 1 }
  cp "$src" "$dst" && echo "created $dst from $src"
}

# json — pretty-print JSON (from file or stdin)
# Usage: cat data.json | json   OR   json data.json
json() {
  if [[ -n "$1" ]]; then
    python3 -m json.tool "$1" | bat --language=json --paging=never
  else
    python3 -m json.tool | bat --language=json --paging=never
  fi
}

# dotenv-check — show all variables defined in .env without their values
dotenv-check() {
  [[ ! -f ".env" ]] && { echo "no .env in cwd"; return 1 }
  grep -v '^#' .env | grep -v '^$' | cut -d= -f1 | sort
}
