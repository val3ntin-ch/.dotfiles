#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Linux: fnm (linked into ~/.local/bin by installLinux.sh) provides node/npx —
# a bare bash right after the install has neither on PATH yet
export PATH="$HOME/.local/bin:$PATH"
if ! command -v npx &>/dev/null && command -v fnm &>/dev/null; then eval "$(fnm env --log-level quiet)"; fi
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

# Claude Code marketplaces + plugins/skills for web dev. Run ./installAiMobile.sh
# instead if you also want React Native. Idempotent — safe to rerun anytime to
# pick up newly added plugins.

step "Claude Code marketplaces"
# claude-plugins-official ships built in — only third-party marketplaces need
# registering. `add` on an already-known marketplace is a harmless no-op.
CLAUDE_MARKETPLACES=(
  mvanhorn/last30days-skill
  JuliusBrussee/caveman
  forrestchang/andrej-karpathy-skills
)
for repo in "${CLAUDE_MARKETPLACES[@]}"; do
  claude plugin marketplace add "$repo" || true
done

step "Claude Code plugins"
CLAUDE_PLUGINS=(
  andrej-karpathy-skills@karpathy-skills
  caveman@caveman
  claude-code-setup@claude-plugins-official
  code-review@claude-plugins-official
  context7@claude-plugins-official
  figma@claude-plugins-official
  frontend-design@claude-plugins-official
  last30days@last30days-skill
  lua-lsp@claude-plugins-official
  playwright@claude-plugins-official
  pr-review-toolkit@claude-plugins-official
  security-guidance@claude-plugins-official
  sentry@claude-plugins-official
  supabase@claude-plugins-official
  superpowers@claude-plugins-official
  typescript-lsp@claude-plugins-official
  vercel@claude-plugins-official
)
for plugin in "${CLAUDE_PLUGINS[@]}"; do
  claude plugin install "$plugin" -y || true
done

step "Web skills (npx skills CLI)"
# Must run from $HOME — the CLI installs into ./.agents/skills relative to cwd,
# and this script's cwd is wherever it was invoked from (typically this repo),
# which would wrongly nest a copy inside the dotfiles checkout.
(cd "$HOME" && npx --yes skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices)
(cd "$HOME" && npx --yes skills add https://github.com/vercel-labs/agent-skills --skill vercel-composition-patterns)

step "Agent configs (agents/)"
# Agents rewrite their own config files (plugins, trusted dirs, hook hashes),
# so these are merged/seeded rather than symlinked — keeps machine paths out
# of the repo. Repo values win on overlapping keys; everything else is kept.
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.config/opencode"
merge_json() {  # merge_json <base> <target>
  local tmp
  tmp="$(mktemp)"
  [[ -f "$2" ]] || echo '{}' > "$2"
  jq -s '.[0] * .[1]' "$2" "$1" > "$tmp" && mv "$tmp" "$2"
}
merge_json "$DOTFILES/agents/claude/settings.base.json" "$HOME/.claude/settings.json"
merge_json "$DOTFILES/agents/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
ln -sf "$DOTFILES/agents/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
if [[ -f "$HOME/.codex/config.toml" ]]; then
  # existing config: only make sure analytics + feedback are off
  for table in analytics feedback; do
    grep -q "^\[$table\]" "$HOME/.codex/config.toml" \
      || printf '\n[%s]\nenabled = false\n' "$table" >> "$HOME/.codex/config.toml"
  done
  # no update dialog on start (it blocks herdr/squad agents): a top-level key,
  # so it must sit before the first [table]
  grep -q '^check_for_update_on_startup' "$HOME/.codex/config.toml" \
    || perl -0pi -e 's/^(?=\[)/check_for_update_on_startup = false\n\n/m' "$HOME/.codex/config.toml"
  # Claude-only plugin whose Stop hook fails in Codex: off in Codex only
  sg='[plugins."security-guidance@claude-plugins-official"]'
  if grep -qF "$sg" "$HOME/.codex/config.toml"; then
    perl -0pi -e 's/(\[plugins\."security-guidance\@claude-plugins-official"\]\n)enabled = true/${1}enabled = false/' "$HOME/.codex/config.toml"
  else
    printf '\n%s\nenabled = false\n' "$sg" >> "$HOME/.codex/config.toml"
  fi
else
  cp "$DOTFILES/agents/codex/config.base.toml" "$HOME/.codex/config.toml"
fi

step "squad (agent teams in herdr)"
# github.com/val3ntin-ch/squad — clone once, fast-forward afterwards
SQUAD_DIR="$HOME/.local/share/squad"
if [[ -d "$SQUAD_DIR/.git" ]]; then
  git -C "$SQUAD_DIR" pull --ff-only -q || echo "  squad: could not update (local changes?) — left as is"
else
  git clone -q https://github.com/val3ntin-ch/squad "$SQUAD_DIR"
fi
"$SQUAD_DIR/install.sh"
# machine setup: Codex rules (squad herdr/git/done never ask) and Claude's
# usage status line (only when no status line is set yet)
"$SQUAD_DIR/bin/squad" permissions

printf '\n\033[1;32m✓ Web Claude skillset installed.\033[0m\n'
