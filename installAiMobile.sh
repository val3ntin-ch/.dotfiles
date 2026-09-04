#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

# Web skillset + React Native. Runs installAi.sh first so this is always a
# strict superset — one list to maintain, no drift between the two scripts.
"$DOTFILES/installAi.sh"

step "React Native skills"
# Installed directly via the `skills` CLI, not `claude plugin install` — the
# marketplace plugin names kept breaking across upstream renames
# (react-native-best-practices/github -> building-react-native-apps/
# testing-react-native-apps, etc). Installing skills by their actual repo
# path instead of a marketplace-plugin alias sidesteps that entirely.
# Must run from $HOME — see installAi.sh's skills step for why.
(cd "$HOME" && npx skills@latest add callstackincubator/agent-skills --skill '*')

printf '\n\033[1;32m✓ Web + React Native Claude skillset installed.\033[0m\n'
