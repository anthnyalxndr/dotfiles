#!/usr/bin/env bash
# PreToolUse(Bash) hook — validates Conventional Commits format on `git commit -m`

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

# Only act on git commit commands with an inline message
if ! echo "$COMMAND" | grep -qE 'git commit'; then
  exit 0
fi

# Extract message from -m "..." or -m '...'
MSG=$(echo "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()
# Match -m followed by single or double quoted string, or heredoc EOF
m = re.search(r'-m\s+[\"\'](.*?)[\"\']', cmd, re.DOTALL)
if m:
    print(m.group(1))
" 2>/dev/null)

# If we couldn't extract the message, allow it through (e.g. heredoc, EDITOR commits)
if [ -z "$MSG" ]; then
  exit 0
fi

CONVENTIONAL_REGEX='^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\([a-z0-9._-]+\))?!?: .+'

if ! echo "$MSG" | grep -qP "$CONVENTIONAL_REGEX" 2>/dev/null; then
  # Fallback to ERE if perl regex not available
  if ! echo "$MSG" | grep -qE "$CONVENTIONAL_REGEX"; then
    echo "BLOCKED: Commit message does not follow Conventional Commits format." >&2
    echo "" >&2
    echo "  Required: <type>(<scope>): <description>" >&2
    echo "  Types:    feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert" >&2
    echo "  Example:  feat(auth): add OAuth2 login support" >&2
    echo "" >&2
    echo "  Your message: $MSG" >&2
    exit 2
  fi
fi

exit 0
