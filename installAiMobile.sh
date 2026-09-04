#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

# Web skillset + React Native. Runs installAi.sh first so this is always a
# strict superset — one list to maintain, no drift between the two scripts.
"$DOTFILES/installAi.sh"

step "React Native marketplace"
claude plugin marketplace add callstackincubator/agent-skills || true

step "React Native plugins"
# NOTE: callstack renamed these upstream at some point — the marketplace now
# ships building-react-native-apps / testing-react-native-apps /
# migrating-to-react-native, not the old react-native-best-practices / github
# names. If this ever fails with "not found in marketplace" again, check
# ~/.claude/plugins/marketplaces/callstack-agent-skills/.claude-plugin/marketplace.json
# for the current plugin names before assuming it's a fluke.
CLAUDE_MOBILE_PLUGINS=(
  building-react-native-apps@callstack-agent-skills
  testing-react-native-apps@callstack-agent-skills
  migrating-to-react-native@callstack-agent-skills
)
for plugin in "${CLAUDE_MOBILE_PLUGINS[@]}"; do
  claude plugin install "$plugin" -y || true
done

printf '\n\033[1;32m✓ Web + React Native Claude skillset installed.\033[0m\n'
