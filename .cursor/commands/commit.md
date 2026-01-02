# commit

Review all unstaged changes in this git repository. Analyze each change to understand its purpose and relationships. Group related changes into logical commits following these rules:

1. Group changes by:
    - Functional area (e.g., chart, financials, news)
    - Type of change (feature, bug fix, refactor, styling)
    - Component dependencies

2. For each group, suggest a commit with:
    - Conventional commit format: `<type>(<scope>): <subject>`
    - Types: feat, fix, refactor, style, docs, test, chore
    - Scope: module/component name
    - Subject: imperative mood, max 50 chars
    - Body (if needed): explain what and why, wrap at 72 chars

3. Present the grouped commits as:
    - A list of files that will be included in each commit
    - The commit message for each
    - A brief explanation of why these changes are grouped together

4. After review, execute the commits one by one, pausing for confirmation between each.
