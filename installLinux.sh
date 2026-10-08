#!/usr/bin/env bash
# Linux bootstrap — same setup as install.sh (macOS) on any distro family:
#   apt (Debian/Ubuntu/Mint/Pop) · dnf (Fedora/RHEL/Alma/Rocky) ·
#   pacman (Arch/Manjaro/EndeavourOS) · zypper (openSUSE)
# Native packages first; anything the distro lacks or ships too old comes from
# the tool's official installer or GitHub release, into ~/.local/bin.
# Safe to rerun. Env overrides:
#   LOGIN_SHELL=fish|zsh|none   default fish (none = don't chsh, e.g. containers)
#   DESKTOP=auto|1|0            Ghostty + Nerd Fonts; auto = only with a GUI session
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-common.sh
source "$DOTFILES/lib/install-common.sh"

[[ "$(uname -s)" == Linux ]] || { echo "installLinux.sh is for Linux — use install.sh on macOS" >&2; exit 1; }

BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
mkdir -p "$BIN" "$OPT"
export PATH="$BIN:$PATH"
SUDO=""
[[ $EUID -eq 0 ]] || SUDO="sudo"

case "$(uname -m)" in
  x86_64|amd64)  RARCH=x86_64  GOARCH=amd64 ;;
  aarch64|arm64) RARCH=aarch64 GOARCH=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# ── 0. Detect package manager ─────────────────────────────────────────────────
# shellcheck source=/dev/null
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *" arch "*|*" manjaro "*)                       PM=pacman ;;
  *" debian "*|*" ubuntu "*)                      PM=apt ;;
  *" fedora "*|*" rhel "*|*" centos "*)           PM=dnf ;;
  *" suse "*|*" opensuse "*|*" opensuse-tumbleweed "*) PM=zypper ;;
  *) echo "unsupported distro: ${PRETTY_NAME:-unknown} (need apt, dnf, pacman or zypper)" >&2; exit 1 ;;
esac
step "Distro: ${PRETTY_NAME:-$ID} ($PM, $RARCH)"

pm_refresh() {
  case $PM in
    apt)    $SUDO apt-get update -qq ;;
    dnf)    $SUDO dnf -y -q makecache ;;
    # Arch doesn't support partial upgrades — sync + upgrade together
    pacman) $SUDO pacman -Syu --noconfirm >/dev/null ;;
    zypper) $SUDO zypper -n -q --gpg-auto-import-keys refresh ;;
  esac
}
# pm_install pkg...  — one batch; if any name is unknown on this distro, retry
# one by one so a single missing package never blocks the rest
pm_install() {
  local install
  case $PM in
    apt)    install=(env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends) ;;
    dnf)    install=(dnf install -y -q) ;;
    pacman) install=(pacman -S --noconfirm --needed) ;;
    zypper) install=(zypper -n -q install --no-recommends) ;;
  esac
  $SUDO "${install[@]}" "$@" >/dev/null 2>&1 && return
  local p out
  for p in "$@"; do
    out="$($SUDO "${install[@]}" "$p" 2>&1)" \
      || { echo "  (not installed via $PM: $p — fallback below if needed)"
           # dependency conflicts: show the solver's explanation, not just a prompt
           grep -A12 -m1 '^Problem' <<<"$out" | sed 's/^/      /' || tail -1 <<<"$out"; }
  done
}

# ── helpers for tools missing or too old in the distro ───────────────────────
have() { command -v "$1" >/dev/null 2>&1; }
# version_ge <have> <want>  (dotted versions)
version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }
link() { ln -sf "$1" "$BIN/$(basename "${2:-$1}")"; }

# gh_fetch <owner/repo> <asset-regex> <dest-file>
# Downloads the first matching asset of the repo's latest GitHub release and
# verifies it against the sha256 GitHub publishes for that asset — a mismatch,
# or an asset with no published sha256, is refused. Only official upstream repos are passed in (see README "Sources").
# Uses GITHUB_TOKEN when set (CI rate limits).
gh_fetch() {
  local repo="$1" pattern="$2" dest="$3" auth=() meta url digest
  [[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  meta="$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/$repo/releases/latest" \
    | jq -c --arg re "$pattern" '[.assets[] | select(.name | test($re; "i"))][0] // empty')"
  [[ -n "$meta" ]] || { echo "  no release asset of $repo matches $pattern" >&2; return 1; }
  url="$(jq -r .browser_download_url <<<"$meta")"
  digest="$(jq -r '.digest // empty' <<<"$meta")"
  curl -fsSL "$url" -o "$dest"
  if [[ "$digest" != sha256:* ]]; then
    echo "  REFUSED: GitHub publishes no sha256 for $(basename "$url") — cannot verify" >&2
    rm -f "$dest"; return 1
  fi
  echo "${digest#sha256:}  $dest" | sha256sum -c --quiet - \
    || { echo "  CHECKSUM MISMATCH for $url — not installing" >&2; rm -f "$dest"; return 1; }
  basename "$url"
}

# gh_release <owner/repo> <asset-regex> <binary>...
# gh_fetch + extract + copy the named binaries into ~/.local/bin.
gh_release() {
  local repo="$1" pattern="$2"; shift 2
  local tmp name b f
  tmp="$(mktemp -d)"
  name="$(gh_fetch "$repo" "$pattern" "$tmp/asset")" || { rm -rf "$tmp"; return 1; }
  mkdir -p "$tmp/x"
  case "$name" in
    *.zip)          unzip -q "$tmp/asset" -d "$tmp/x" ;;
    *.tar.gz|*.tgz) tar -xzf "$tmp/asset" -C "$tmp/x" ;;
    *.tar.xz)       tar -xJf "$tmp/asset" -C "$tmp/x" ;;
    *)              cp "$tmp/asset" "$tmp/x/$1" ;;
  esac
  for b in "$@"; do
    f="$(find "$tmp/x" -type f -name "$b" | head -1)"
    [[ -n "$f" ]] || { echo "  $b not found in $name" >&2; rm -rf "$tmp"; return 1; }
    install -m 755 "$f" "$BIN/$b"
  done
  rm -rf "$tmp"
  echo "  installed $* from $repo ($name)"
}

# ── 1. Base + native packages ─────────────────────────────────────────────────
step "Native packages"
pm_refresh
# generic list; per-distro names below. Anything absent gets a fallback in step 2.
case $PM in
  apt)    BASE=(build-essential curl git ca-certificates unzip xz-utils file fontconfig sudo procps findutils)
          PKGS=(zsh fish stow jq ripgrep fzf zoxide bat fd-find golang-go gh git-delta eza lazygit
                vivid neovim watchman ffmpeg poppler-utils imagemagick 7zip python3 xclip wl-clipboard) ;;
  dnf)    BASE=(gcc gcc-c++ make curl git ca-certificates unzip xz file fontconfig sudo procps-ng util-linux-user findutils)
          PKGS=(zsh fish stow jq ripgrep fzf zoxide bat fd-find golang gh git-delta eza lazygit
                vivid neovim watchman ffmpeg-free poppler-utils ImageMagick 7zip python3 xclip wl-clipboard) ;;
  pacman) BASE=(base-devel curl git ca-certificates unzip xz file fontconfig sudo procps-ng findutils)
          PKGS=(zsh fish stow jq ripgrep fzf zoxide bat fd go github-cli git-delta eza lazygit
                vivid ouch yazi starship neovim ffmpeg poppler imagemagick 7zip resvg python xclip wl-clipboard) ;;
  zypper) BASE=(gcc gcc-c++ make curl git ca-certificates unzip xz file fontconfig sudo procps findutils)
          PKGS=(zsh fish stow jq ripgrep fzf zoxide bat fd go gh git-delta eza lazygit
                vivid neovim ffmpeg poppler-tools ImageMagick 7zip python3 xclip wl-clipboard) ;;
esac
pm_install "${BASE[@]}"
# openSUSE minimal/container images ship busybox-gawk, which blocks real gawk
# (fish needs awk). Swap only that stub; never force-resolve anything else.
if [[ $PM == zypper ]] && rpm -q busybox-gawk >/dev/null 2>&1; then
  $SUDO zypper -n -q install --force-resolution gawk >/dev/null
fi
pm_install "${PKGS[@]}"
# Debian/Ubuntu ship bat as `batcat` and fd as `fdfind`
have bat || { have batcat && link "$(command -v batcat)" bat; }
have fd  || { have fdfind && link "$(command -v fdfind)" fd; }

# ── 2. Fallbacks: missing or too old in the distro ────────────────────────────
step "Upstream installs for missing/outdated tools"
RUST="${RARCH}-unknown-linux-(musl|gnu)"
# LazyVim needs nvim >= 0.11.2; Debian/Ubuntu LTS ship much older
nvim_ver="$(nvim --version 2>/dev/null | sed -n 's/^NVIM v\([0-9.]*\).*/\1/p')"
if [[ -z "$nvim_ver" ]] || ! version_ge "$nvim_ver" 0.11.2; then
  nv_arch=$([[ $RARCH == x86_64 ]] && echo x86_64 || echo arm64)
  rm -rf "$OPT/nvim" && mkdir -p "$OPT/nvim"
  gh_fetch neovim/neovim "^nvim-linux-${nv_arch}\\.tar\\.gz$" "$OPT/nvim.tar.gz" >/dev/null
  tar -xzf "$OPT/nvim.tar.gz" -C "$OPT/nvim" --strip-components=1 && rm -f "$OPT/nvim.tar.gz"
  link "$OPT/nvim/bin/nvim"
  echo "  installed nvim $("$BIN/nvim" --version | head -1)"
fi
# fish config runs `fzf --fish` (needs fzf >= 0.48)
fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
if [[ -z "$fzf_ver" ]] || ! version_ge "$fzf_ver" 0.48; then
  gh_release junegunn/fzf "linux_${GOARCH}\\.tar\\.gz$" fzf
fi
have lazygit || gh_release jesseduffield/lazygit "Linux_$([[ $RARCH == x86_64 ]] && echo x86_64 || echo arm64)\\.tar\\.gz$" lazygit
have eza     || gh_release eza-community/eza "eza_${RARCH}-unknown-linux-gnu\\.tar\\.gz$" eza
have delta   || gh_release dandavison/delta "${RUST}\\.tar\\.gz$" delta
have vivid   || gh_release sharkdp/vivid "${RUST}\\.tar\\.gz$" vivid
have ouch    || gh_release ouch-org/ouch "${RUST}\\.tar\\.gz$" ouch
have yazi    || gh_release sxyazi/yazi "${RUST}\\.zip$" yazi ya
have gh      || gh_release cli/cli "linux_${GOARCH}\\.tar\\.gz$" gh
have zoxide  || gh_release ajeetdsouza/zoxide "${RUST}\\.tar\\.gz$" zoxide
# optional (SVG previews in yazi); upstream ships no aarch64 build
have resvg   || gh_release linebender/resvg "resvg-linux-${RARCH}\\.tar\\.gz$" resvg \
  || echo "  resvg unavailable for $RARCH — yazi SVG previews disabled (optional)"
have starship || curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN" >/dev/null
if ! have fnm; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell >/dev/null
  link "$HOME/.local/share/fnm/fnm"
fi
# pyenv / rbenv — same version managers as macOS, cloned (distro copies lag)
[[ -d "$HOME/.pyenv" ]] || git clone -q --depth=1 https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
link "$HOME/.pyenv/bin/pyenv"
if [[ ! -d "$HOME/.rbenv" ]]; then
  git clone -q --depth=1 https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
  git clone -q --depth=1 https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
fi
link "$HOME/.rbenv/bin/rbenv"
have watchman || echo "  watchman not packaged here — only needed for React Native"

# ── 3. Herdr + coding agents ──────────────────────────────────────────────────
step "Herdr + coding agents"
have herdr  || curl -fsSL https://herdr.dev/install.sh | sh
have claude || curl -fsSL https://claude.ai/install.sh | bash
if ! have opencode; then
  # --no-modify-path: rc files are managed by this repo
  curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
  link "$HOME/.opencode/bin/opencode"
fi
echo "  Conductor is macOS-only — skipped"

# ── 4. Desktop: Ghostty + Nerd Fonts ──────────────────────────────────────────
DESKTOP="${DESKTOP:-auto}"
if [[ "$DESKTOP" == auto ]]; then
  [[ -n "${XDG_CURRENT_DESKTOP:-}${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] && DESKTOP=1 || DESKTOP=0
fi
if [[ "$DESKTOP" == 1 ]]; then
  step "Ghostty + Nerd Fonts"
  if ! have ghostty; then
    # official distro repos only (Arch extra, openSUSE) — COPR/snap/PPA builds
    # are third-party, so other distros get a pointer to Ghostty's own docs
    case $PM in
      pacman|zypper) pm_install ghostty ;;
    esac
    have ghostty || echo "  Ghostty: not in official $PM repos — install per https://ghostty.org/docs/install/binary"
  fi
  FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
  # marker written only after every font is in place — a failed or partial run
  # is retried next time instead of being skipped
  if [[ ! -f "$FONT_DIR/.installed" ]]; then
    mkdir -p "$FONT_DIR"
    for font in JetBrainsMono NerdFontsSymbolsOnly; do
      gh_fetch ryanoasis/nerd-fonts "^${font}\\.tar\\.xz$" "$FONT_DIR/$font.tar.xz" >/dev/null
      tar -xJf "$FONT_DIR/$font.tar.xz" -C "$FONT_DIR" && rm -f "$FONT_DIR/$font.tar.xz"
    done
    fc-cache -f "$FONT_DIR" >/dev/null
    touch "$FONT_DIR/.installed"
  fi
else
  step "Ghostty + Nerd Fonts — skipped (no desktop session; DESKTOP=1 to force)"
fi

# ── 5-10. Shared steps (lib/install-common.sh) ────────────────────────────────
stow_dotfiles
LOGIN_SHELL="${LOGIN_SHELL:-fish}"
set_login_shell "$LOGIN_SHELL"
fish_plugins
# Node first: codex, pnpm, yarn and markdownlint come from npm on Linux
node_lts @openai/codex pnpm yarn markdownlint-cli2
herdr_integrations
yazi_plugins

next_steps
