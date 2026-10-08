# $ZDOTDIR/.zshenv  (~/.config/zsh/.zshenv)
# Runs for EVERY shell type — interactive, non-interactive, scripts.
# Rule: no subprocess output, no prompts, no `eval`, no slow stuff.
# Only: pure variable assignments and PATH manipulation.

# ── XDG Base Directory ────────────────────────────────────────────────────
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ── ZSH runtime files (out of git-tracked ZDOTDIR) ───────────────────────
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# ── Dotfiles location ────────────────────────────────────────────────────
export DOTFILES_DIR="$HOME/.dotfiles"

# ── Antidote (plugin manager) ─────────────────────────────────────────────
export ANTIDOTE_HOME="$XDG_DATA_HOME/antidote"

# ── Editors ───────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R -F -X --use-color -j4"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# ── Locale ────────────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── man → bat ─────────────────────────────────────────────────────────────
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ── Homebrew (macOS) ──────────────────────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -d "/opt/homebrew" ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"        # Apple Silicon
  elif [[ -d "/usr/local/Homebrew" ]]; then
    export HOMEBREW_PREFIX="/usr/local"           # Intel Mac
  fi
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
  fi
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1                # update on your terms
fi

# ── Local binaries ────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ── pnpm ──────────────────────────────────────────────────────────────────
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export PATH="$PNPM_HOME:$PATH"

# ── bun ───────────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ── Go ────────────────────────────────────────────────────────────────────
export GOPATH="$XDG_DATA_HOME/go"
export PATH="$GOPATH/bin:$PATH"

# ── Java ───────────────────────────────────────────────────────────────────
# Zulu JDK 17 — required for React Native Android builds
# If the path doesn't exist on this machine, the export is harmless.
[[ -d "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home" ]] && \
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"

# ── Android SDK ────────────────────────────────────────────────────────────
# Required for React Native Android development.
# ANDROID_HOME points to the SDK root; platform-tools has adb, emulator has avd manager.
if [[ -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PATH="$ANDROID_HOME/emulator:$PATH"
  export PATH="$ANDROID_HOME/platform-tools:$PATH"
fi

# ── Git editor ────────────────────────────────────────────────────────────
# GIT_EDITOR overrides $EDITOR specifically for git commit messages, rebases, etc.
# Kept separate from $EDITOR so you can override just git's editor independently.
export GIT_EDITOR="nvim"

# ── Bat theme ─────────────────────────────────────────────────────────────
export BAT_THEME="Catppuccin Mocha"

# ── fzf ───────────────────────────────────────────────────────────────────
# Catppuccin Mocha palette
export FZF_DEFAULT_OPTS="
  --height=50%
  --layout=reverse
  --border=rounded
  --prompt='❯ '
  --pointer='▸'
  --marker='✓'
  --info=inline
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=border:#6c7086,label:#cdd6f4
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-u:preview-half-page-up'
  --bind='ctrl-d:preview-half-page-down'
"

if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git --exclude node_modules"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git --exclude node_modules"
fi

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range=:100 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --tree --level=2 --color=always {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap"


# ── Privacy / telemetry opt-outs ──────────────────────────────────────────
# Mirrored in fish conf.d/env.fish and agents/claude/settings.base.json.
export DO_NOT_TRACK=1                       # generic convention (Caveman CLI, others)
export DISABLE_TELEMETRY=1                  # Claude Code usage metrics
export DISABLE_ERROR_REPORTING=1            # Claude Code error reports
export VERCEL_PLUGIN_TELEMETRY=off          # Vercel Claude plugin
export CAVEMAN_TELEMETRY=0                  # Caveman CLI
export NEXT_TELEMETRY_DISABLED=1            # Next.js
export TURBO_TELEMETRY_DISABLED=1           # Turborepo
export EXPO_NO_TELEMETRY=1                  # Expo
export ASTRO_TELEMETRY_DISABLED=1           # Astro
export GATSBY_TELEMETRY_DISABLED=1          # Gatsby
export STORYBOOK_DISABLE_TELEMETRY=1        # Storybook
