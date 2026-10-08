#!/usr/bin/env bash
# Repo health checks — run by CI on every PR, and locally before pushing:
#   .github/check.sh
# Needs: bash zsh fish shellcheck lua(luac) python3 stow gitleaks herdr
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
FAILED=()
section() { printf '\n\033[1;36m── %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31m✗ %s\033[0m\n' "$1"; FAILED+=("$1"); }
ok() { printf '\033[1;32m✓ %s\033[0m\n' "$1"; }
# tracked files matching a pattern (pipe-safe, no word splitting surprises)
tracked() { git ls-files -z -- "$@"; }

section "Shell scripts: syntax + shellcheck"
while IFS= read -r -d '' f; do
  bash -n "$f" || fail "bash syntax: $f"
done < <(tracked '*.sh')
tracked '*.sh' | xargs -0 shellcheck -S warning || fail "shellcheck"

section "Zsh syntax"
while IFS= read -r -d '' f; do
  zsh -n "$f" || fail "zsh syntax: $f"
done < <(tracked .zshenv '.config/zsh/.zshenv' '.config/zsh/.zprofile' '.config/zsh/.zshrc' '.config/zsh/conf.d/*.zsh')

section "Fish syntax"
while IFS= read -r -d '' f; do
  fish --no-execute "$f" || fail "fish syntax: $f"
done < <(tracked '*.fish')

section "Lua syntax"
while IFS= read -r -d '' f; do
  luac -p "$f" || fail "lua syntax: $f"
done < <(tracked '*.lua')

section "TOML / JSON parse"
tracked '*.toml' '*.json' | python3 -c '
import sys, json, tomllib
bad = 0
for f in sys.stdin.read().split("\0"):
    if not f:
        continue
    try:
        with open(f, "rb") as fh:
            tomllib.load(fh) if f.endswith(".toml") else json.load(fh)
    except Exception as e:
        print(f"{f}: {e}"); bad = 1
sys.exit(bad)
' || fail "toml/json parse"

section "No machine-specific home paths"
# configs must use ~ / $HOME — a hardcoded /Users/<name> breaks every other machine
if git grep -nIE '/(Users|home)/[a-z][a-z0-9_-]*/' -- ':!.github/check.sh'; then
  fail "hardcoded home path"
fi

section "Secrets (gitleaks)"
gitleaks dir . --no-banner --redact || fail "gitleaks"

section "Herdr config"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/.config/herdr"
cp .config/herdr/config.toml "$TMP_HOME/.config/herdr/"
HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME/.config" herdr config check || fail "herdr config check"
rm -rf "$TMP_HOME/.config/herdr"

section "Stow into a fresh HOME"
if stow --target="$TMP_HOME" --restow . 2>&1; then
  for p in agents install.sh installAi.sh installAiMobile.sh .github README.md; do
    [[ -e "$TMP_HOME/$p" ]] && fail "stow leaked repo-only path into HOME: $p"
  done
  [[ -L "$TMP_HOME/.zshenv" ]] || fail "stow did not link ~/.zshenv"
else
  fail "stow"
fi

section "Fresh login shells load env"
# catches env files that exist but never get sourced (e.g. $ZDOTDIR/.zshenv)
for sh in zsh fish; do
  out="$(env -i HOME="$TMP_HOME" PATH=/usr/bin:/bin TERM=dumb "$(command -v "$sh")" -l -c 'echo "$EDITOR|$DO_NOT_TRACK"' 2>/dev/null | tail -1)"
  [[ "$out" == "nvim|1" ]] && ok "$sh login env" || fail "$sh login env (got '$out', want 'nvim|1')"
done
command -v fish >/dev/null && env -i HOME="$TMP_HOME" PATH=/usr/bin:/bin TERM=dumb "$(command -v fish)" -c 'functions -q hdev' \
  || fail "fish: hdev function not found"

printf '\n'
if ((${#FAILED[@]})); then
  printf '\033[1;31m%d check(s) failed:\033[0m\n' "${#FAILED[@]}"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
printf '\033[1;32mAll checks passed.\033[0m\n'
