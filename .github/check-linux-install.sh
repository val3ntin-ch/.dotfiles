#!/usr/bin/env bash
# Verifies installLinux.sh produced a working setup. CI runs it inside each
# distro container after the install; also usable on a real Linux machine.
set -uo pipefail
FAILED=()
fail() { printf '\033[1;31m✗ %s\033[0m\n' "$1"; FAILED+=("$1"); }
ok() { printf '\033[1;32m✓ %s\033[0m\n' "$1"; }
export PATH="$HOME/.local/bin:$PATH"
version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }

for c in fish zsh stow nvim herdr starship git gh lazygit delta eza bat fd rg fzf zoxide \
         jq yazi ya vivid ouch go fnm pyenv rbenv claude opencode; do
  command -v "$c" >/dev/null && ok "$c" || fail "missing: $c"
done

v="$(nvim --version 2>/dev/null | sed -n 's/^NVIM v\([0-9.]*\).*/\1/p')"
version_ge "${v:-0}" 0.11.2 && ok "nvim $v >= 0.11.2" || fail "nvim too old: ${v:-none}"
fzf --fish >/dev/null 2>&1 && ok "fzf --fish" || fail "fzf lacks --fish (needs >= 0.48)"

# node toolchain lives under fnm
eval "$(fnm env --log-level quiet)"
for c in node npm codex pnpm yarn markdownlint-cli2 tree-sitter; do
  command -v "$c" >/dev/null && ok "$c (fnm)" || fail "missing: $c"
done

herdr config check >/dev/null && ok "herdr config" || fail "herdr config check"
[[ -L "$HOME/.zshenv" ]] && ok "stow linked ~/.zshenv" || fail "~/.zshenv not linked"
for p in agents lib installLinux.sh .github; do
  [[ -e "$HOME/$p" ]] && fail "repo-only path stowed into HOME: $p"
done

# fresh login shells must load the env (PATH, EDITOR, telemetry opt-outs)
for sh in zsh fish; do
  out="$(env -i HOME="$HOME" USER="${USER:-$(id -un)}" PATH=/usr/bin:/bin TERM=dumb "$(command -v "$sh")" -l -c \
    'echo "$EDITOR|$DO_NOT_TRACK|$(command -v herdr >/dev/null && echo herdr)"' 2>/dev/null | tail -1)"
  [[ "$out" == "nvim|1|herdr" ]] && ok "$sh login env" || fail "$sh login env (got '$out', want 'nvim|1|herdr')"
done
env -i HOME="$HOME" PATH=/usr/bin:/bin TERM=dumb "$(command -v fish)" -c 'functions -q hdev' \
  && ok "fish hdev" || fail "fish: hdev not found"

printf '\n'
if ((${#FAILED[@]})); then
  printf '\033[1;31m%d check(s) failed:\033[0m\n' "${#FAILED[@]}"; printf '  - %s\n' "${FAILED[@]}"; exit 1
fi
printf '\033[1;32mLinux install verified.\033[0m\n'
