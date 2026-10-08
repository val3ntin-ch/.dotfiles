#!/usr/bin/env bash
# doctor.sh — repair + check this dotfiles setup on any machine (macOS/Linux).
#   ./doctor.sh            repair, then check
#   ./doctor.sh --check    check only (changes nothing)
# Repairs are safe to repeat: they only pull, re-link and regenerate caches.
# Every ✗ line says how to fix what it can't fix itself.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-common.sh
source "$DOTFILES/lib/install-common.sh"
export PATH="$HOME/.local/bin:$PATH"
OS="$(uname -s)"
CHECK_ONLY=0
[[ "${1:-}" == --check ]] && CHECK_ONLY=1

FAILED=()
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[1;31m✗\033[0m %s\n      → %s\n' "$1" "$2"; FAILED+=("$1"); }
note() { printf '  \033[1;33m•\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
# limit <seconds> cmd... — network steps must never hang the doctor
# (macOS has no `timeout`; perl ships with both OSes)
limit() { local t="$1"; shift; perl -e 'alarm shift; exec @ARGV or die' "$t" "$@"; }

if ((!CHECK_ONLY)); then
  step "Repair"

  # 1. latest dotfiles — fast-forward only, never over local work
  branch="$(git -C "$DOTFILES" branch --show-current)"
  if [[ "$branch" == main && -z "$(git -C "$DOTFILES" status --porcelain)" ]]; then
    limit 60 git -C "$DOTFILES" pull --ff-only -q && ok "dotfiles up to date ($(git -C "$DOTFILES" log --oneline -1))" \
      || note "git pull failed — offline? continuing with the local copy"
  else
    note "dotfiles not pulled: on '$branch' or uncommitted changes (git -C ~/.dotfiles status)"
  fi

  # 2. stale copies shadowing Homebrew's (macOS: ~/.local/bin comes first on
  #    PATH, so an old curl/webi install silently wins — e.g. herdr 0.8)
  if [[ "$OS" == Darwin ]]; then
    for bin in herdr gh; do
      if [[ -e "$HOME/.local/bin/$bin" && -x "$(brew --prefix 2>/dev/null)/bin/$bin" ]]; then
        rm -f "$HOME/.local/bin/$bin" && ok "removed stale ~/.local/bin/$bin (Homebrew's is used)"
      fi
    done
  fi

  # 3. re-link dotfiles (new/moved files after a pull)
  if stow_dotfiles >/dev/null; then ok "dotfiles re-stowed"
  else bad "stow failed (a real file blocks a link?)" "cd ~/.dotfiles && stow --target=\$HOME --restow . — read the conflict, move that file aside, rerun"; fi

  # 4. regenerate shell caches — rebuilt automatically on next shell start
  rm -f "$HOME/.cache/zsh/"zcompdump* "$HOME/.config/zsh/.zcompdump"* \
        "$HOME/.config/zsh/.zsh_plugins.zsh" "$HOME/.cache/zsh/"*-completion.zsh
  rm -rf "$HOME/.cache/zsh/zcompcache"
  ok "zsh completion + antidote caches cleared (rebuilt on next zsh start)"
  if have fish; then
    limit 120 fish -c 'fisher update' >/dev/null 2>&1 && ok "fish plugins synced to fish_plugins" \
      || note "fisher update failed or timed out (network?) — run: fish -c 'fisher update'"
  fi

  # 5. nvim plugins back to the committed lazy-lock.json
  if have nvim; then
    limit 300 nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && ok "nvim plugins restored to lazy-lock.json" \
      || note "Lazy restore failed — open nvim and run :Lazy restore"
  fi

  # 6. yazi plugins
  if have ya; then
    (cd "$HOME/.config/yazi" && limit 120 ya pkg upgrade --discard >/dev/null 2>&1) && ok "yazi plugins synced" \
      || note "yazi plugin sync failed — run: yaziupdate"
  fi

  # 7. herdr: agent hooks + reload config into a running server
  if have herdr; then
    if herdr_integrations >/dev/null 2>&1; then ok "herdr agent hooks reinstalled"
    else bad "herdr agent hooks failed" "herdr integration install claude (then codex, opencode) to see the error"; fi
    # capture first: `herdr status | grep -q` + pipefail misreads SIGPIPE as "not running"
    if [[ "$(herdr status 2>/dev/null)" == *"status: running"* ]]; then
      if herdr server reload-config >/dev/null 2>&1; then ok "herdr config reloaded into running server"
      else bad "herdr config reload failed" "herdr server reload-config"; fi
    fi
  fi
fi

step "Checks"

# tools — npm globals (codex on Linux) live under fnm's Node
have fnm && eval "$(fnm env --log-level quiet)"
n=${#FAILED[@]}
for c in git stow fish zsh nvim herdr jq fzf zoxide rg fd bat eza lazygit delta yazi starship gh fnm claude codex opencode; do
  have "$c" || bad "$c not found" "$([[ $OS == Darwin ]] && echo ./install.sh || echo ./installLinux.sh)"
done
((${#FAILED[@]} == n)) && ok "all required tools on PATH"

# herdr: version + commands hdev uses
if have herdr; then
  hv="$(herdr --version | awk '{print $2}')"
  hpath="$(command -v herdr)"
  missing=()
  for sub in "agent list" "agent focus" "pane process-info" "pane swap"; do
    # shellcheck disable=SC2086
    herdr $sub --help >/dev/null 2>&1 || missing+=("$sub")
  done
  if ((${#missing[@]})); then
    if [[ $OS == Darwin && "$hpath" != "$(brew --prefix 2>/dev/null)/bin/herdr" ]]; then
      fix="stale copy shadows Homebrew's: rm $hpath (./doctor.sh does it), then exec \$SHELL"
    elif [[ $OS == Darwin ]]; then fix="brew upgrade herdr"
    else fix="herdr update"; fi
    bad "herdr $hv at $hpath lacks: ${missing[*]} (hdev needs them)" "$fix"
  else
    ok "herdr $hv ($hpath) supports hdev"
  fi
  herdr config check >/dev/null 2>&1 && ok "herdr config valid" || bad "herdr config invalid" "herdr config check"
fi

# fresh login shells: PATH, env, hdev
for sh in fish zsh; do
  have "$sh" || continue
  out="$(env -i HOME="$HOME" USER="${USER:-$(id -un)}" PATH=/usr/bin:/bin TERM=dumb "$(command -v "$sh")" -l -c \
    'echo "$EDITOR|$DO_NOT_TRACK|$(command -v herdr >/dev/null && echo herdr)|$(command -v claude >/dev/null && echo claude)"' 2>/dev/null | tail -1)"
  if [[ "$out" == "nvim|1|herdr|claude" ]]; then ok "$sh login shell: env + PATH"
  else bad "$sh login shell env wrong (got '$out')" "./doctor.sh after git pull; then exec $sh"; fi
done
have fish && { env -i HOME="$HOME" PATH=/usr/bin:/bin TERM=dumb "$(command -v fish)" -c 'functions -q hdev' \
  && ok "hdev available in fish" || bad "hdev missing in fish" "re-stow: ./doctor.sh, then exec fish"; }
# source only the functions file (definitions only) — an interactive zsh would
# run the whole .zshrc, which writes caches and may clone plugins (not read-only)
have zsh && { env -i HOME="$HOME" PATH=/usr/bin:/bin TERM=dumb "$(command -v zsh)" -c \
  'source "$HOME/.config/zsh/conf.d/functions.zsh" && whence -w hdev' >/dev/null 2>&1 \
  && ok "hdev available in zsh" || bad "hdev missing in zsh" "re-stow: ./doctor.sh, then exec zsh"; }

# current shell may be stale: the loaded hdev must match the repo's
note "already-open shells keep old functions — run: exec \$SHELL (or open a new tab)"

# login shell
if [[ "$OS" == Darwin ]]; then login="$(dscl . -read "$HOME" UserShell | awk '{print $2}')"
else login="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)"; fi
ok "login shell: $login"

# git identity + GitHub auth
git config --get user.email >/dev/null && ok "git identity set" \
  || bad "git identity missing" "create ~/.config/git/config.local with [user] name/email"
have gh && { gh auth status >/dev/null 2>&1 && ok "gh logged in" || bad "gh not logged in" "gh auth login"; }

printf '\n'
if ((${#FAILED[@]})); then
  printf '\033[1;31m%d problem(s) need you — each has its fix above.\033[0m\n' "${#FAILED[@]}"
  exit 1
fi
printf '\033[1;32mAll good. Restart open shells: exec $SHELL\033[0m\n'
