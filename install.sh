#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

# ── 0. Xcode CLI tools (C compiler for nvim-treesitter) ──────────────────────
if ! xcode-select -p &>/dev/null; then
  step "Xcode CLI tools"
  xcode-select --install
  echo "  Waiting for Xcode CLI tools to finish installing..."
  until xcode-select -p &>/dev/null; do sleep 5; done
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
  stow tmux vivid ouch bat eza fnm pnpm go pyenv rbenv \
  tree-sitter watchman node

# ── 3. Yazi + required dependencies ──────────────────────────────────────────
step "Yazi + dependencies"
brew install \
  yazi ffmpeg-full sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick-full \
  markdownlint-cli2
brew link ffmpeg-full imagemagick-full -f --overwrite

# ── 4. Sesh (custom tap) ──────────────────────────────────────────────────────
step "Sesh"
brew install joshmedeski/sesh/sesh

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

# ── 7. Default shell → zsh ────────────────────────────────────────────────────
step "Default shell → zsh"
ZSH_PATH="$(brew --prefix)/bin/zsh"
grep -qF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
chsh -s "$ZSH_PATH"

# ── 8. Fish plugins ───────────────────────────────────────────────────────────
step "Fish plugins"
fish -c "
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
  fisher install
"

# ── 9. Tmux plugins (TPM) ─────────────────────────────────────────────────────
step "Tmux plugins"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
[[ -d "$TPM_DIR" ]] || git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
# install_plugins needs a running server to read the plugin list from tmux.conf
tmux start-server 2>/dev/null || true
tmux new-session -d -s _setup 2>/dev/null || true
"$TPM_DIR/bin/install_plugins"
tmux kill-session -t _setup 2>/dev/null || true

# ── 10. Node LTS ──────────────────────────────────────────────────────────────
step "Node LTS"
eval "$(fnm env --log-level quiet)"
fnm install --lts
npm install -g neovim tree-sitter-cli

printf '\n\033[1;32m✓ Done. Open a new terminal — zsh is your default shell.\033[0m\n'
printf '  Next steps:\n'
printf '    1. Set git identity (once per machine):\n'
printf '       cat > ~/.config/git/config.local <<EOF\n'
printf '       [user]\n'
printf '           name  = Your Name\n'
printf '           email = you@example.com\n'
printf '       EOF\n'
printf '    2. nvim                  → first launch installs all plugins (~2-5 min)\n'
printf '    3. :LazyHealth           → verify everything is working\n'
printf '    4. ya pkg install        → install yazi plugins (optional)\n\n'
