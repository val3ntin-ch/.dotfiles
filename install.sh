#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-common.sh
source "$DOTFILES/lib/install-common.sh"

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
stow_dotfiles

# ── 7. Default shell → fish ───────────────────────────────────────────────────
# zsh stays installed and configured; switch back with LOGIN_SHELL=zsh ./install.sh
LOGIN_SHELL="${LOGIN_SHELL:-fish}"
# brew's copy, not /bin/zsh — macOS ships an older zsh earlier on some PATHs
set_login_shell "$LOGIN_SHELL" "$(brew --prefix)/bin/$LOGIN_SHELL"

# ── 8-11. Fish plugins · herdr integrations · Node LTS · Yazi plugins ────────
fish_plugins
herdr_integrations
node_lts
yazi_plugins

next_steps
