#!/bin/bash
set -euo pipefail

# Claude Code CLI adapter for dual review
# Usage: claude-reviewer.sh <diff_content_file> <diff_stat>

DIFF_FILE="$1"
DIFF_STAT="$2"

if ! command -v claude >/dev/null 2>&1; then
  echo "VERDICT: SKIPPED"
  echo "REASON: claude command not found"
  exit 0
fi

PROMPT="$(cat <<PROMPT_END
You are a code reviewer for a pre-push gate. Review the following git diff
and determine whether it should be allowed to push.

Review for these issues (in priority order):
1. Security: exposed secrets, credentials, API keys, tokens in source code
2. Logic errors: contradictions, impossible conditions, broken invariants
3. Bugs: null/undefined mishandling, off-by-one errors, race conditions, resource leaks
4. Test gaps: changed business logic without corresponding test changes

Do NOT reject for:
- Formatting or code style
- Naming preferences
- Performance unless it is a clear regression on hot paths
- Missing documentation
- Refactoring suggestions

Respond with your analysis (keep it concise), then end with EXACTLY one of:

VERDICT: APPROVED

or

VERDICT: REJECTED
REASON: <one line per issue>

--- Diff Statistics ---
${DIFF_STAT}

--- Diff Content ---
$(cat "$DIFF_FILE")
PROMPT_END
)"

claude -p \
  --no-session-persistence \
  --allowedTools "" \
  --model sonnet \
  "$PROMPT"
