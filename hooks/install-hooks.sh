#!/bin/bash
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set global hooks path
git config --global core.hooksPath "$HOOKS_DIR"

echo "Global git hooks path set to: $HOOKS_DIR"
echo ""
echo "AI dual review (Claude Code + Codex) will run on every git push."
echo ""
echo "To skip review for a single push:  SKIP_AI_REVIEW=1 git push"
echo "To uninstall:                      bash $HOOKS_DIR/uninstall-hooks.sh"
