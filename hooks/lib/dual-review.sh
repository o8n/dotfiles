#!/bin/bash
set -euo pipefail

# Dual AI code review orchestrator
# Usage: dual-review.sh <mode> <base_ref>
#   mode=STAGED  → review staged changes (pre-commit)
#   mode=<oid>   → review commit range (pre-push)

MODE="$1"
BASE_ARG="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMEOUT="${AI_REVIEW_TIMEOUT:-120}"
MAX_DIFF_LINES="${AI_REVIEW_MAX_DIFF_LINES:-10000}"

# --- Diff extraction ---

if [ "$MODE" = "STAGED" ]; then
  # Pre-commit: review staged changes
  DIFF_STAT=$(git diff --cached --stat 2>/dev/null || echo "(diff stat unavailable)")
  DIFF_CONTENT=$(git diff --cached 2>/dev/null || echo "(diff unavailable)")
  BASE_REF="HEAD"
else
  # Pre-push: review commit range
  LOCAL_OID="$MODE"
  REMOTE_OID="$BASE_ARG"

  if [ "$REMOTE_OID" = "0000000000000000000000000000000000000000" ] || [ -z "$REMOTE_OID" ]; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    MERGE_BASE=$(git merge-base "$DEFAULT_BRANCH" "$LOCAL_OID" 2>/dev/null || echo "$LOCAL_OID~1")
    DIFF_RANGE="${MERGE_BASE}..${LOCAL_OID}"
    BASE_REF="$DEFAULT_BRANCH"
  else
    DIFF_RANGE="${REMOTE_OID}..${LOCAL_OID}"
    BASE_REF="$REMOTE_OID"
  fi

  DIFF_STAT=$(git diff --stat "$DIFF_RANGE" 2>/dev/null || echo "(diff stat unavailable)")
  DIFF_CONTENT=$(git diff "$DIFF_RANGE" 2>/dev/null || echo "(diff unavailable)")
fi

# Check empty diff
DIFF_LINES=$(echo "$DIFF_CONTENT" | wc -l | tr -d ' ')
if [ "$DIFF_LINES" -le 1 ]; then
  echo "No code changes detected. Skipping AI review."
  exit 0
fi

# Truncate large diffs
if [ "$DIFF_LINES" -gt "$MAX_DIFF_LINES" ]; then
  TRUNCATED_LINES=$((MAX_DIFF_LINES * 8 / 10))
  DIFF_CONTENT="$(echo "$DIFF_CONTENT" | head -n "$TRUNCATED_LINES")

... (diff truncated: ${DIFF_LINES} lines total, showing first ${TRUNCATED_LINES})"
fi

# Write diff to temp file for Claude reviewer
DIFF_TMPFILE=$(mktemp)
echo "$DIFF_CONTENT" > "$DIFF_TMPFILE"
trap 'rm -f "$DIFF_TMPFILE" "$CLAUDE_RESULT" "$CODEX_RESULT"' EXIT

# --- Parallel execution ---

CLAUDE_RESULT=$(mktemp)
CODEX_RESULT=$(mktemp)

echo "=== AI Code Review ==="
echo "Running Claude Code and Codex reviews in parallel..."
echo ""

# Wait for a process with timeout
wait_with_timeout() {
  local pid=$1
  local timeout=$2
  local name=$3

  ( sleep "$timeout" && kill "$pid" 2>/dev/null && echo "VERDICT: TIMEOUT" > "$4" ) &
  local watcher_pid=$!

  if wait "$pid" 2>/dev/null; then
    kill "$watcher_pid" 2>/dev/null || true
    wait "$watcher_pid" 2>/dev/null || true
    return 0
  else
    kill "$watcher_pid" 2>/dev/null || true
    wait "$watcher_pid" 2>/dev/null || true
    return 1
  fi
}

# Launch both reviewers
bash "$SCRIPT_DIR/claude-reviewer.sh" "$DIFF_TMPFILE" "$DIFF_STAT" > "$CLAUDE_RESULT" 2>&1 &
CLAUDE_PID=$!

# Codex: use --uncommitted for staged changes, --base for commit range
if [ "$MODE" = "STAGED" ]; then
  bash "$SCRIPT_DIR/codex-reviewer.sh" "--uncommitted" > "$CODEX_RESULT" 2>&1 &
else
  bash "$SCRIPT_DIR/codex-reviewer.sh" "$BASE_REF" > "$CODEX_RESULT" 2>&1 &
fi
CODEX_PID=$!

# Wait with timeouts
wait_with_timeout "$CLAUDE_PID" "$TIMEOUT" "Claude" "$CLAUDE_RESULT"
CLAUDE_EXIT=$?

wait_with_timeout "$CODEX_PID" "$TIMEOUT" "Codex" "$CODEX_RESULT"
CODEX_EXIT=$?

# --- Result parsing ---

parse_verdict() {
  local result_file=$1
  local name=$2

  if grep -q "^VERDICT: APPROVED" "$result_file"; then
    echo "APPROVED"
  elif grep -q "^VERDICT: REJECTED" "$result_file"; then
    echo "REJECTED"
  elif grep -q "^VERDICT: SKIPPED" "$result_file"; then
    echo "SKIPPED"
  elif grep -q "^VERDICT: TIMEOUT" "$result_file"; then
    echo "TIMEOUT"
  else
    echo "ERROR"
  fi
}

get_reason() {
  local result_file=$1
  grep "^REASON:" "$result_file" | sed 's/^REASON: //' || true
}

CLAUDE_VERDICT=$(parse_verdict "$CLAUDE_RESULT" "Claude")
CODEX_VERDICT=$(parse_verdict "$CODEX_RESULT" "Codex")

# --- Output results ---

echo "=== Review Results ==="
echo ""
echo "[Claude Code] $CLAUDE_VERDICT"
if [ "$CLAUDE_VERDICT" = "REJECTED" ]; then
  CLAUDE_REASON=$(get_reason "$CLAUDE_RESULT")
  [ -n "$CLAUDE_REASON" ] && echo "  Reason: $CLAUDE_REASON"
elif [ "$CLAUDE_VERDICT" = "ERROR" ]; then
  echo "  (Raw output):"
  tail -5 "$CLAUDE_RESULT" | sed 's/^/  /'
fi

echo ""
echo "[Codex]       $CODEX_VERDICT"
if [ "$CODEX_VERDICT" = "REJECTED" ]; then
  CODEX_REASON=$(get_reason "$CODEX_RESULT")
  [ -n "$CODEX_REASON" ] && echo "  Reason: $CODEX_REASON"
elif [ "$CODEX_VERDICT" = "ERROR" ]; then
  echo "  (Raw output):"
  tail -5 "$CODEX_RESULT" | sed 's/^/  /'
fi

echo ""

# --- Decision ---

PASS=true
for verdict in "$CLAUDE_VERDICT" "$CODEX_VERDICT"; do
  case "$verdict" in
    APPROVED|SKIPPED) ;;
    REJECTED)
      PASS=false
      ;;
    TIMEOUT|ERROR)
      if [ "${AI_REVIEW_FAIL_OPEN:-0}" = "1" ]; then
        echo "Warning: Review error/timeout, but AI_REVIEW_FAIL_OPEN=1 so allowing commit."
      else
        PASS=false
      fi
      ;;
  esac
done

if [ "$PASS" = true ]; then
  echo "Both reviews passed. Commit allowed."
  exit 0
else
  echo "Commit blocked. Fix the issues above, or use git commit --no-verify to bypass."
  exit 1
fi
