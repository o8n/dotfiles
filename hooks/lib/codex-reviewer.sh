#!/bin/bash
set -euo pipefail

# OpenAI Codex CLI adapter for dual review
# Usage: codex-reviewer.sh <--uncommitted | base_ref>

REF_ARG="$1"

if ! command -v codex >/dev/null 2>&1; then
  echo "VERDICT: SKIPPED"
  echo "REASON: codex command not found"
  exit 0
fi

REVIEW_PROMPT="$(cat <<'PROMPT_END'
Review for these issues (in priority order):
1. Security: exposed secrets, credentials, API keys, tokens in source code
2. Logic errors: contradictions, impossible conditions, broken invariants
3. Bugs: null/undefined mishandling, off-by-one errors, race conditions, resource leaks
4. Test gaps: changed business logic without corresponding test changes

Do NOT reject for: formatting, naming, performance micro-optimizations, docs, refactoring.

End your response with EXACTLY one of:

VERDICT: APPROVED

or

VERDICT: REJECTED
REASON: <one line per issue>
PROMPT_END
)"

if [ "$REF_ARG" = "--uncommitted" ]; then
  codex review "$REVIEW_PROMPT" --uncommitted
else
  codex review "$REVIEW_PROMPT" --base "$REF_ARG"
fi
