#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

# ── 0. Xcode CLI tools (C compiler for nvim-treesitter) ──────────────────────
# Install if missing AND update if outdated — Homebrew refuses to build with
# stale tools. With CLT installed, `softwareupdate --list` shows it only when
# an update exists. When missing, this flag file makes it list the package
# anyway (the flag also lists it when current, so set it only when missing).
step "Xcode CLI tools"
CLT_FLAG=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
xcode-select -p &>/dev/null || touch "$CLT_FLAG"
CLT_LABEL="$(softwareupdate --list 2>/dev/null \
  | sed -n 's/^\* Label: \(Command Line Tools for Xcode.*\)$/\1/p' \
  | sort -V | tail -1)"
if [[ -n "$CLT_LABEL" ]]; then
  echo "  installing $CLT_LABEL"
  sudo softwareupdate --install "$CLT_LABEL" --verbose
else
  echo "  up to date"
fi
rm -f "$CLT_FLAG"
# fallback: softwareupdate listed nothing and no tools exist → GUI installer
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "  Waiting for Xcode CLI tools to finish installing..."
  until xcode-select -p &>/dev/null; do sleep 5; done
fi
# full Xcode.app (React Native) blocks git/brew/clang until its license is
# accepted — again after every Xcode update. `check` fails when unaccepted.
if [[ "$(xcode-select -p)" == *Xcode*.app* ]] && ! xcodebuild -license check &>/dev/null; then
  echo "  accepting Xcode license"
  sudo xcodebuild -license accept
fi

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
step "Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -x /usr/local/bin/brew    ]] && eval "$(/usr/local/bin/brew shellenv)"
fi
brew update

# ── 2. Core tools ─────────────────────────────────────────────────────────────
step "Core tools"
brew install \
  fish zsh starship antidote neovim git gh lazygit git-delta \
  stow vivid ouch bat eza fnm pnpm yarn go pyenv rbenv \
  tree-sitter watchman node
# `install` is a no-op on a machine that already has an older neovim — force
# it current every run. Real motivation: hit a neovim-core inlay-hint crash
# (nvim/neovim#39772, fixed upstream) that only reproduced on a stale 0.12.5;
# staying current avoids landing on a version with a known-fixed bug.
brew upgrade neovim || true

# ── 3. Yazi + required dependencies ──────────────────────────────────────────
step "Yazi + dependencies"
brew install \
  yazi ffmpeg-full sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick-full \
  markdownlint-cli2
brew link ffmpeg-full imagemagick-full -f --overwrite

# ── 4. Herdr + coding agents ──────────────────────────────────────────────────
step "Herdr + coding agents"
brew install herdr
# Claude Code via its native installer, not the brew cask — native auto-updates
# in the background; the cask only moves on `brew upgrade`
command -v claude &>/dev/null || curl -fsSL https://claude.ai/install.sh | bash
brew install --cask codex
# `install` leaves an already-installed cask on its old version
brew upgrade --cask codex || true
# Conductor self-updates; a copy dragged into /Applications by hand would make
# the cask install abort on "already an App at ..."
[[ -d /Applications/Conductor.app ]] || brew install --cask conductor
# opencode's official tap — newer brew refuses untrusted taps until trusted
brew tap anomalyco/tap
brew trust anomalyco/tap 2>/dev/null || true
brew install anomalyco/tap/opencode
# Remove copies installed outside brew (curl/webi/npm) — ~/.local/bin and fnm's
# node bin sit ahead of brew on PATH, so a stale copy silently wins.
for bin in herdr gh webi; do
  [[ -e "$HOME/.local/bin/$bin" ]] && rm -f "$HOME/.local/bin/$bin" && echo "  removed ~/.local/bin/$bin"
done
command -v npm &>/dev/null && npm ls -g @openai/codex &>/dev/null && npm uninstall -g @openai/codex

# ── 5. Ghostty + fonts ────────────────────────────────────────────────────────
step "Ghostty + fonts"
brew install --cask ghostty font-jetbrains-mono-nerd-font font-symbols-only-nerd-font

# ── 6. Stow dotfiles ──────────────────────────────────────────────────────────
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
  [[ "$(realpath "$target")" == "$DOTFILES"/* ]] && continue
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

# ── 7. Default shell → fish ───────────────────────────────────────────────────
# zsh stays installed and configured; switch back with LOGIN_SHELL=zsh ./install.sh
LOGIN_SHELL="${LOGIN_SHELL:-fish}"
step "Default shell → $LOGIN_SHELL"
SHELL_PATH="$(brew --prefix)/bin/$LOGIN_SHELL"
grep -qF "$SHELL_PATH" /etc/shells || echo "$SHELL_PATH" | sudo tee -a /etc/shells
# chsh always prompts for the password — skip it when already the login shell
if [[ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" != "$SHELL_PATH" ]]; then
  chsh -s "$SHELL_PATH"
else
  echo "  already $LOGIN_SHELL"
fi

# ── 8. Fish plugins ───────────────────────────────────────────────────────────
step "Fish plugins"
fish -c "
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
  fisher update
"

# ── 9. Herdr agent integrations ───────────────────────────────────────────────
step "Herdr agent integrations"
# hooks that report each agent's state (working / waiting / done) to herdr's
# sidebar — idempotent, rewrites to the current version on rerun
for agent in claude codex opencode; do
  herdr integration install "$agent"
done

# ── 10. Node LTS ──────────────────────────────────────────────────────────────
step "Node LTS"
eval "$(fnm env --log-level quiet)"
fnm install --lts
npm install -g neovim tree-sitter-cli

# ── 11. Yazi plugins ───────────────────────────────────────────────────────────
step "Yazi plugins"
# `upgrade` (not `install`) so pinned plugin revs in package.toml always sync to
# whatever yazi version brew just installed — a stale pinned rev vs. a newer yazi
# core is exactly what broke plugin loading last time (yazi's plugin API moved).
# --discard: plugins/ is pure upstream cache, never hand-edited — any local diff
# (partial upgrade, prior manual `rm -rf` fix) should never block this from running.
(cd "$HOME/.config/yazi" && ya pkg upgrade --discard)

printf '\n\033[1;32m✓ Done. Open a new terminal — fish is your default shell.\033[0m\n'
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
printf '    7. herdr                 → then `hdev <project>` (agent; add -e for nvim)\n\n'
