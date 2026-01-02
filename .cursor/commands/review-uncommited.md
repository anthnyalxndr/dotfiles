# review-uncommited

Review the current uncommitted changes, check for errors, check for patterns that aren't idiomatic, check for unnecessary repetition, check for any other instances of the code not following best practices, and provide suggested fixes for all flagged code. When generating fixes, look across files to ensure repetition isn't occurring and changes are following the patterns of the existing codebase.

## Steps:

1. **Get uncommitted changes**: First, identify all files with uncommitted changes using git status.

2. **Read changed files**: Read the contents of all modified files to understand what has changed.

3. **Check for errors**:
    - Syntax errors
    - Type errors
    - Runtime errors
    - Missing imports
    - Unused variables/imports
    - Invalid prop types or type mismatches

4. **Check for non-idiomatic patterns**:
    - React/TypeScript patterns that don't follow best practices
    - Inconsistent naming conventions
    - Missing error handling
    - Improper state management
    - Inefficient re-renders or missing memoization where needed
    - Incorrect hook usage

5. **Check for unnecessary repetition**:
    - Duplicate code blocks
    - Similar logic that could be extracted to utilities or custom hooks
    - Repeated patterns that should be componentized
    - Duplicate constants or magic numbers/strings

6. **Check for best practices violations**:
    - Accessibility issues
    - Performance issues
    - Security concerns
    - Missing error boundaries
    - Improper data fetching patterns
    - Inconsistent styling approaches

7. **Cross-file consistency checks**:
    - Compare patterns with similar components in the codebase
    - Ensure consistent API/data fetching patterns
    - Ensure consistent component structure
    - Ensure consistent naming conventions
    - Check if similar functionality exists elsewhere that could be reused

8. **Provide suggested fixes**:
    - For each issue found, provide specific code suggestions
    - Show before/after examples
    - Reference similar patterns from the codebase when applicable
    - Prioritize fixes by severity (errors first, then best practices)

9. **Summary**: Provide a comprehensive summary of all issues found and fixes suggested, organized by file and priority.
