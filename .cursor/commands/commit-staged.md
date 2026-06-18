# commit-staged

Analyze the currently staged git changes and create an idiomatic commit message following conventional commit format, then commit the changes.

## Steps:

1. **Get staged changes:**
    - Use `git diff --cached` to see what's staged
    - Review the actual changes to understand their purpose

2. **Analyze the changes:**
    - Identify the type of change (feat, fix, refactor, style, docs, test, chore)
    - Determine the scope (component/module affected)
    - Understand the purpose and impact

3. **Create commit message:**
    - Format: `<type>(<scope>): <subject>`
    - Types: feat, fix, refactor, style, docs, test, chore, perf
    - Scope: relevant module/component (optional but recommended)
    - Subject: imperative mood, lowercase, no period, max 50 chars
    - Body (if needed): explain what and why, wrap at 72 chars
    - Footer (if needed): breaking changes, issue references

4. **Commit the changes:**
    - Use `git commit -m "<message>"` with the generated message
    - If the message needs a body, use `git commit -m "<subject>" -m "<body>"`

## Guidelines:

- Use conventional commit format for consistency
- Keep subject line concise and descriptive
- Group related changes logically (if multiple files, ensure they're related)
- Use imperative mood ("add feature" not "added feature" or "adds feature")
- Reference issues/PRs in footer if applicable
- Be specific about what changed and why

Execute this process now for the currently staged changes.
