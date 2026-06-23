#!/usr/bin/env bash
# PreToolUse(Bash) hook — blocks commits when production code is staged without test changes

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git commit'; then
  exit 0
fi

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED" ]; then
  exit 0
fi

# Check for production source files (non-test files in common src locations)
PROD_FILES=$(echo "$STAGED" | grep -vE '(\.test\.|\.spec\.|_test\.|test_|/tests?/|/test/|/__tests__/)' | grep -E '\.(ts|tsx|js|jsx|py)$' || true)

# Check for test files
TEST_FILES=$(echo "$STAGED" | grep -E '(\.test\.|\.spec\.|_test\.|test_|/tests?/|/test/|/__tests__/)' | grep -E '\.(ts|tsx|js|jsx|py)$' || true)

if [ -n "$PROD_FILES" ] && [ -z "$TEST_FILES" ]; then
  echo "BLOCKED: Production code staged without any test changes." >&2
  echo "" >&2
  echo "  Production files staged:" >&2
  echo "$PROD_FILES" | sed 's/^/    /' >&2
  echo "" >&2
  echo "  Add or update tests before committing." >&2
  echo "  To override (not recommended): add a test file or amend the staged set." >&2
  exit 2
fi

exit 0
