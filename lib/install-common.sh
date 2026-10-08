#!/usr/bin/env bash
# Steps shared by install.sh (macOS) and installLinux.sh — sourced, not run.
# Callers set DOTFILES and `set -euo pipefail` before sourcing.

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

stow_dotfiles() {
  step "Stowing dotfiles"
  # back up any real dirs that would conflict with stow symlinks
  [[ -d "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
  # back up any real files where stow needs a symlink (e.g. app-created
  # ~/.config/git/ignore or ~/.config/lazygit/config.yml) — otherwise stow
  # aborts the whole run with a conflict
  (cd "$DOTFILES" && git ls-files -- .config .zshenv) | while IFS= read -r f; do
    target="$HOME/$f"
    # skip if missing, a symlink, or already resolving into the repo
    # (folded stow dirs make repo files look like real files at $HOME)
    [[ -e "$target" && ! -L "$target" ]] || continue
    # perl, not realpath(1): macOS only ships realpath since 13
    [[ "$(perl -MCwd -e 'print Cwd::abs_path(shift)' "$target")" == "$DOTFILES"/* ]] && continue
    mv "$target" "$target.bak"
    echo "  conflict backed up: $target → $target.bak"
  done
  # ensure runtime dirs exist before first use
  mkdir -p \
    "$HOME/.local/state/less" \
    "$HOME/.local/state/zsh" \
    "$HOME/.local/share/zsh" \
    "$HOME/.cache/zsh" \
    "$HOME/.config/git"
  (cd "$DOTFILES" && stow --target="$HOME" --restow .)
}

# set_login_shell <shell-name> [path]  — name "none" skips (CI, containers)
set_login_shell() {
  local name="$1" path="${2:-}" current
  step "Default shell → $name"
  if [[ "$name" == none ]]; then echo "  skipped (LOGIN_SHELL=none)"; return; fi
  [[ -n "$path" ]] || path="$(command -v "$name")"
  grep -qxF "$path" /etc/shells || echo "$path" | sudo tee -a /etc/shells >/dev/null
  if [[ "$(uname -s)" == Darwin ]]; then
    current="$(dscl . -read "$HOME" UserShell | awk '{print $2}')"
  else
    current="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)"
  fi
  # chsh always prompts for the password — skip it when already the login shell
  if [[ "$current" != "$path" ]]; then
    chsh -s "$path"
  else
    echo "  already $name"
  fi
}

fish_plugins() {
  step "Fish plugins"
  fish -c "
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher update
  "
}

herdr_integrations() {
  step "Herdr agent integrations"
  # hooks that report each agent's state (working / waiting / done) to herdr's
  # sidebar — idempotent, rewrites to the current version on rerun.
  # Each agent creates its config dir on first launch; create them now so the
  # hooks install on a fresh machine before any agent has run.
  mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.config/opencode"
  for agent in claude codex opencode; do
    herdr integration install "$agent"
  done
}

# node_lts [extra global npm packages...]
node_lts() {
  step "Node LTS"
  eval "$(fnm env --log-level quiet)"
  fnm install --lts
  # npm blocks package install scripts by default; allow them only for the
  # packages that need one (tree-sitter-cli fetches its binary, pnpm/yarn
  # set up their shims) — never a blanket allow
  npm install -g --allow-scripts=tree-sitter-cli,pnpm,yarn neovim tree-sitter-cli "$@"
}

yazi_plugins() {
  step "Yazi plugins"
  # `upgrade` (not `install`) so pinned plugin revs in package.toml always sync to
  # whatever yazi version was just installed — a stale pinned rev vs. a newer yazi
  # core is exactly what broke plugin loading last time (yazi's plugin API moved).
  # --discard: plugins/ is pure upstream cache, never hand-edited — any local diff
  # (partial upgrade, prior manual `rm -rf` fix) should never block this from running.
  (cd "$HOME/.config/yazi" && ya pkg upgrade --discard)
}

next_steps() {
  printf '\n\033[1;32m✓ Done. Open a new terminal — %s is your default shell.\033[0m\n' "${LOGIN_SHELL:-fish}"
  printf '  Next steps:\n'
  printf '    1. Set git identity (once per machine):\n'
  printf '       cat > ~/.config/git/config.local <<EOF\n'
  printf '       [user]\n'
  printf '           name  = Your Name\n'
  printf '           email = you@example.com\n'
  printf '       EOF\n'
  printf '    2. nvim                  → first launch installs all plugins (~2-5 min)\n'
  printf '    3. :LazyHealth           → verify everything is working\n'
  printf '    4. If `ya pkg upgrade` above changed package.toml, commit it —\n'
  printf '       keeps other machines in sync with the plugin revs that just worked.\n'
  printf '    5. Log in once: gh auth login · claude · codex · opencode auth login\n'
  printf '    6. Agent plugins/skills + agent configs (telemetry off) — run one of:\n'
  printf '         ./installAi.sh        (web-only skillset)\n'
  printf '         ./installAiMobile.sh  (web + React Native skillset)\n'
  printf '    7. herdr                 → then `hdev <project>` (nvim + agent; -o agent only)\n\n'
}
