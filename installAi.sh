#!/usr/bin/env bash
set -euo pipefail

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
  security-guidance@claude-plugins-official
  supabase@claude-plugins-official
  superpowers@claude-plugins-official
  typescript-lsp@claude-plugins-official
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

printf '\n\033[1;32m✓ Web Claude skillset installed.\033[0m\n'
