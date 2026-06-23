#!/usr/bin/env bash
# PreToolUse(Bash) hook — blocks dangerous git operations

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

# Block force push
if echo "$COMMAND" | grep -qE 'git push.+(-f\b|--force\b)'; then
  echo "BLOCKED: Force push is not allowed — it can destroy remote history." >&2
  echo "If you need to overwrite, use --force-with-lease and get explicit user confirmation first." >&2
  exit 2
fi

# Block direct push to main or master
if echo "$COMMAND" | grep -qE 'git push( [^ ]+)? (origin )?(main|master)( |$)'; then
  echo "BLOCKED: Direct push to main/master is not allowed." >&2
  echo "Create a branch, open a PR, and merge through the normal review process." >&2
  exit 2
fi

# Block --no-verify on commits
if echo "$COMMAND" | grep -qE 'git commit.+(--no-verify|-n\b)'; then
  echo "BLOCKED: Bypassing commit hooks (--no-verify) is not allowed." >&2
  echo "Fix the underlying issue that the hook is catching." >&2
  exit 2
fi

exit 0
