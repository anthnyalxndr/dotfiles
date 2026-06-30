# Global Development Standards

## Initiative

Never ask the user to do a task that you could do yourself - whether it's purely on your own or with the help an mcp server, a plugin, a script, or the claude in chrome extension. When considering asking the user to do a task, always consider if you could do it yourself first.

## Starting a New Project

When starting a new project, **default to scaffolding from the personal templates repo**
[`anthnyalxndr/copier-templates`](https://github.com/anthnyalxndr/copier-templates) instead of
hand-rolling config. It bakes in the standards in this file (Conventional Commits, trunk-based,
git hooks, lint/typecheck/test, pnpm/uv, CI, security) plus an agent layer (`AGENTS.md` +
`CLAUDE.md` → `@AGENTS.md` + `.cursor/rules`, `.claude/`, `.mcp.json`).

- **Scaffold:** `uvx copier copy gh:anthnyalxndr/copier-templates <dest>`
- **Types:** `base`, `ts-frontend` (`next-mui` | `vite`), `ts-backend` (Hono), `python` (uv), `docker`
- **Bootstrap git after copy** (hooks attach to `.git`, so order matters): `git init` → install
  deps (`pnpm install`, or `uv sync && uv run pre-commit install`) → first Conventional commit.
- **Propagate later template improvements** into an existing repo with `uvx copier update`.

Because a scaffolded repo already satisfies the Git Commit Hooks, Code Quality, Package
Management, and Testing sections below, do **not** re-ask those setup questions for it. Only
hand-roll a new project (and ask those questions) when no template fits.

## Workflow

- Before executing any non-trivial task, first assess the appropriate breadth and depth of planning for the work at hand, then produce a plan at that level: steps, files you'll touch, commands you'll run, and what success looks like.
- "Non-trivial" = anything that writes files, runs shell commands with side effects, modifies git state, or touches more than one file — and anything similar in nature to those examples, not just literal matches. Pure questions, reads, and single-line edits don't need a plan.
- After drafting a plan, recursively review and revise it for accuracy and thoroughness. Keep iterating until you're genuinely confident in it before executing. One pass is rarely enough.
- If a plan turns out to be wrong mid-execution, stop and re-plan rather than improvising.

## Planning & Backlog

- Keep **one committed planning backlog per repo** as the single source of truth for planned,
  deferred, and follow-up work. Default: `docs/backlog.md` (or the repo's established equivalent —
  match what's already there; don't add a parallel one).
- Record every TODO / deferred item / fast-follow there as a **stable, numbered item**. Don't
  renumber existing items (specs, ADRs, commits, and code comments reference them by number); append
  new ids, and mark shipped items done rather than deleting them.
- **Don't scatter planning** across parallel surfaces — no root `todo.md`/`todo.html`, no per-feature
  todo files, no burying work only in `// TODO` comments. When you spot work mid-task, add a backlog
  item and reference it by number instead.
- The in-session agent task list (the ephemeral todo UI) is **scratch for the current task's steps
  only** — never a persistent backlog, and never mirrored into the backlog doc.
- If a repo already has scattered planning docs, consolidate them into the single backlog and
  retire/redirect the rest (leave a one-line pointer so old links resolve).

## Commit Messages

Do not add Co-Authored-By trailers to commit messages.

All commits MUST use Conventional Commits format:

```
<type>(<scope>): <description>
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `revert`

Examples:

- `feat(auth): add OAuth2 support`
- `fix(api): handle null response from upstream`
- `test(utils): add unit tests for date helpers`
- `chore(deps): bump eslint to 9.x`

## Branching (Trunk-Based Development)

- **Never commit directly to `main` or `master`** — always work on a branch
- Branch names: `<type>/<short-description>` (e.g., `feat/add-oauth`, `fix/null-response`)
- Keep branches short-lived (merge within 1–2 days)
- Never use `--force` push. Never bypass hooks with `--no-verify`.

## Testing

- **Every production code change must be accompanied by test changes**
- Run tests before committing — do not commit if tests fail
- TypeScript/JS: `vitest` or `jest`. Python: `pytest`.
- Test files: `*.test.ts`, `*.spec.ts`, `test_*.py`, `*_test.py`

## Git Commit Hooks

Ask the user if the project should have pre-commit hooks that block commits if any of the following fail:

1. **Linting** — `eslint` (TS/JS) or `ruff check` (Python)
2. **Type checking** — `tsc --noEmit` / `npm run typecheck` (TS/JS) or `mypy` (Python)
3. **All existing tests pass** — `vitest run` / `jest` (TS/JS) or `pytest` (Python)

Use **Husky + lint-staged** for TS/JS projects and **pre-commit** for Python projects.
When setting up a new project or when hooks are missing, set them up before writing any other code.

## Code Quality

Ask the user if the project should have code quality checks and if so, which of the following ones (or others).

- **TypeScript/JS:** run `eslint --fix` and `prettier --write` before committing
- **Python:** run `ruff check --fix` and `ruff format` before committing
- Do not suppress linter errors with inline ignore comments without a written justification

## Package Management

- **Prefer `pnpm`** when starting new JavaScript/TypeScript projects
- Use `pnpm init`, `pnpm add`, `pnpm install`, etc. instead of `npm` or `yarn`

## Security

- Make suggestions to fix insecure credential / secret storage and usage.
- Never read, log, print, or display `.env` files or any file containing secrets
- Do not commit credentials, tokens, or API keys — check `git diff --cached` before committing
- Sensitive files: `.env`, `.env.*`, `*.pem`, `*.key`, `*_rsa`, `*.p12`

## Local CI Runner

Self-hosted GitHub Actions runners on this Mac are the default CI/CD compute. Tooling lives in
[`anthnyalxndr/local-ci-runner`](https://github.com/anthnyalxndr/local-ci-runner) (scripts symlinked onto `PATH`).

- **`t0k0n` org repos** run CI/CD on the local runner by default (`runs-on: ${{ vars.RUNNER_LABEL || 'self-hosted' }}`).
  Just commit and push as normal; watch results with `gh run watch` — no special handling.
- **Personal private repos (just-in-time):** when starting work on a **private** `anthnyalxndr/*` repo that uses
  GitHub Actions, check for a repo-level runner with `gh api repos/anthnyalxndr/<name>/actions/runners`. If none and
  the workflows target `self-hosted`, provision one: `setup-local-runner repo anthnyalxndr/<name>`.
  **Never** do this for public repos (a fork PR can run arbitrary code on the machine).
- **Override (Mac off / traveling):** `runner-label cloud <org>` routes runs to GitHub-hosted cloud;
  `runner-label local <org>` switches back.
