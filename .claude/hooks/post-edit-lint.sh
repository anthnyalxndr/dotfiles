#!/usr/bin/env bash
# PostToolUse(Edit|Write) hook — runs linter on edited file (non-blocking)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # PostToolUse wraps in tool_response; file path is in tool_input
    path = d.get('tool_input', {}).get('file_path', '')
    print(path)
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

case "$EXT" in
  py)
    if command -v ruff &>/dev/null; then
      ruff check --fix --quiet "$FILE_PATH" 2>/dev/null || true
      ruff format --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  ts|tsx|js|jsx|mjs|cjs)
    # Try project-local eslint first, then global
    ESLINT=""
    if [ -x "$(git rev-parse --show-toplevel 2>/dev/null)/node_modules/.bin/eslint" ]; then
      ESLINT="$(git rev-parse --show-toplevel)/node_modules/.bin/eslint"
    elif command -v eslint &>/dev/null; then
      ESLINT="eslint"
    fi

    if [ -n "$ESLINT" ]; then
      "$ESLINT" --fix --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

# Always exit 0 — linting is advisory, not a blocker
exit 0
