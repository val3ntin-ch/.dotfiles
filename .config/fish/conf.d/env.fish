# ~/.config/fish/conf.d/env.fish
# Environment variables — mirrors zsh .zshenv

# ── XDG Base Directory ────────────────────────────────────────────────────
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state
mkdir -p $XDG_CACHE_HOME/fish $XDG_STATE_HOME/fish

# ── Dotfiles location ─────────────────────────────────────────────────────
set -gx DOTFILES_DIR $HOME/.dotfiles

# ── Editors ───────────────────────────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx LESS "-R -F -X --use-color -j4"
set -gx LESSHISTFILE $HOME/.local/state/less/history

# ── man → bat ─────────────────────────────────────────────────────────────
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx MANROFFOPT -c

# ── bat ───────────────────────────────────────────────────────────────────
set -gx BAT_THEME "Catppuccin Mocha"

# ── ripgrep ───────────────────────────────────────────────────────────────
set -gx RIPGREP_CONFIG_PATH $HOME/.config/ripgrep/config

# ── fzf — Catppuccin Mocha ────────────────────────────────────────────────
set -gx FZF_DEFAULT_OPTS "
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

if command -q fd
    set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git --exclude node_modules"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git --exclude node_modules"
end

set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --line-range=:100 {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --icons --tree --level=2 --color=always {}'"
set -gx FZF_CTRL_R_OPTS "--preview 'echo {}' --preview-window=down:3:wrap"

# ── LS_COLORS via vivid (Catppuccin Mocha) ────────────────────────────────
if command -q vivid
    set -gx LS_COLORS (vivid generate catppuccin-mocha 2>/dev/null)
end

# ── EZA_COLORS (Catppuccin Mocha) ─────────────────────────────────────────
set -gx EZA_COLORS "\
uu=38;5;116:\
un=38;5;108:\
gu=38;5;116:\
gn=38;5;108:\
sn=38;5;114:\
sb=38;5;108:\
da=38;5;110:\
ga=38;5;114:\
gm=38;5;220:\
gd=38;5;203:\
gr=38;5;116:\
gc=38;5;203:\
hd=38;5;141;1:\
lp=38;5;116:\
xx=38;5;108:\
ur=38;5;220:\
uw=38;5;203:\
ux=38;5;114:\
ue=38;5;114:\
gw=38;5;203:\
gx=38;5;114:\
tw=38;5;203:\
tx=38;5;114:"
set -gx EZA_ICONS_AUTO 1

# ── grep / gcc colors (Catppuccin) ────────────────────────────────────────
set -gx GREP_COLORS "ms=38;5;203:mc=38;5;203:sl=:cx=:fn=38;5;110:ln=38;5;114:bn=38;5;116:se=38;5;108"
set -gx GCC_COLORS 'error=01;38;5;203:warning=38;5;220:note=38;5;110:caret=38;5;114:locus=01:quote=01'

# ── Locale ────────────────────────────────────────────────────────────────
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# ── Git ───────────────────────────────────────────────────────────────────
set -gx GIT_EDITOR nvim
if command -q delta
    set -gx GIT_PAGER delta
    set -gx DELTA_FEATURES catppuccin-mocha
end

# ── Homebrew ──────────────────────────────────────────────────────────────
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_NO_AUTO_UPDATE 1
