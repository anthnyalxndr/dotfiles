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
- **Adopt GitHub Issues task management** once the repo has a GitHub remote: run `/task-init` (see
  Planning & Tasks). The template writes the AGENTS.md section and the allowlist; `/task-init` creates
  the labels, the issue forms, and the planning location.

Because a scaffolded repo already satisfies the Git Commit Hooks, Code Quality, Package
Management, and Testing sections below, do **not** re-ask those setup questions for it. Only
hand-roll a new project (and ask those questions) when no template fits.

## Workflow

- Before executing any non-trivial task, first assess the appropriate breadth and depth of planning for the work at hand, then produce a plan at that level: steps, files you'll touch, commands you'll run, and what success looks like.
- "Non-trivial" = anything that writes files, runs shell commands with side effects, modifies git state, or touches more than one file — and anything similar in nature to those examples, not just literal matches. Pure questions, reads, and single-line edits don't need a plan.
- After drafting a plan, recursively review and revise it for accuracy and thoroughness. Keep iterating until you're genuinely confident in it before executing. One pass is rarely enough.
- If a plan turns out to be wrong mid-execution, stop and re-plan rather than improvising.

## Time & Effort Estimation

- When asked how long something will take — or to size, scope, or estimate any task, feature,
  project, sprint, or backlog, or to give a deadline, ETA, or timeline — use the `time-estimation`
  skill instead of giving a single hand-waved number. It decomposes the work, sense-checks each
  piece by walking the concrete steps, and produces a realistic range adjusted for human-only,
  AI-only, or human+AI execution. This applies even when the request never uses the word "estimate".

## Planning & Tasks

- **Default to GitHub Issues through `gh task`** (repo `anthnyalxndr/gh-task`) as the single source of
  truth for planned, deferred, and follow-up work in any repo with a GitHub remote. The extension
  enforces the rules: `create` refuses a task without a title, a description, at least one acceptance
  criterion, and a priority; `ready` is the dependency-ready set (open, labeled `agent` by the owner and
  not edited by anyone else since, no open blocker or sub-issue, no status label). Leaves (tasks and
  bugs) live flat in the code repo, one PR to `main` each. Initiatives and the pinned Plan live in a
  planning repo recorded in `git config gh-task.plan-repo`: the repo itself when it is private, a
  private companion `<repo>-tasks` when it is public. Ordering is `--blocked-by`; integration work is a
  leaf blocked by the leaves it integrates; `--stack-on` lands ordered leaves as stacked PRs. Adopt in a
  repo with `/task-init`, which also converts a leftover `backlog/` store with `gh task migrate`. Keep
  exactly one store per repo (decided 2026-10-06).
  - **Drive it through `gh task`, never through raw `gh issue` writes.** Reads use `gh issue view`,
    `gh issue list`, and `gh task ready | initiatives | plan show`. Writes go through `gh task create`,
    `start`, `check`, `done`, `plan set`, and `triage`, which keep labels, parents, and bodies
    consistent. Start task work by reading the repo's AGENTS.md "Task management" section.
  - **Adding a task: gather the required fields first, and ASK when any is missing.** A task needs an
    outcome-focused title, a description (the why and the outcome, not implementation steps), at least
    one testable acceptance criterion, a priority, and a parent initiative (`--parent <n>`) or
    `--standalone` with a reason. If the intent is too vague to write those, ask targeted questions
    before creating; never invent acceptance detail. Search first
    (`gh search issues --owner anthnyalxndr "<words>"`) to avoid duplicates.
  - **In-session UX** (skills): `/task-init`, `/task-add`, `/task-refine`, `/task-status`,
    `/task-plan [guidance]` (rank the ready set into an ordered next-up list on the pinned Plan issue;
    `/task-next` reads it first), `/task-next` (work the next ready issue end to end to a draft PR),
    `/task-triage` (decide which owner-authored issues an unattended agent may do alone),
    `/task-autopilot` (launch or schedule the unattended loop).
  - **Autonomous loop with a human gate:** `task-autopilot` runs `/task-next` once per issue: claim with
    `gh task start`, implement (TDD), tick criteria with `gh task check` as each is proven, repo verify
    gate (e.g. `pnpm verify`), draft PR linked with `gh task done`, stop. **Never auto-merge.** It runs
    `claude -p` with `--permission-mode dontAsk`, allows only the six `gh task` subcommands the loop
    needs plus git and package-script forms, denies `git merge`, `git reset`, force pushes,
    `gh pr merge`, raw `gh issue` writes, and package runners, and refuses to launch unless the base
    branch requires a pull request that the owner cannot bypass. The human merges.
  - **Caveats:** readiness trusts the owner's `agent` label, so triage or label by hand before expecting
    the loop to pick something up; a leaf has no children, so split oversized work into sibling leaves
    under an initiative with `/task-refine`; `main` must carry a pull-request ruleset in every repo the
    loop runs in.
- **Lightweight fallback — a single `docs/backlog.md`:** for throwaway repos with no GitHub remote,
  keep one committed `docs/backlog.md` of stable, numbered items. Don't run both; when a repo adopts
  `gh task`, **retire `docs/backlog.md` to a one-line pointer**.
- **Universal rules (whichever store):**
  - **Stable ids** — never renumber existing items (specs, ADRs, commits, and comments reference them
    by number); append new ids; mark shipped items done rather than deleting them.
  - **Don't scatter planning** across parallel surfaces — no root `todo.md`/`todo.html`, no per-feature
    todo files, no burying work only in `// TODO` comments. Record it as an issue and reference it by
    number.
  - The in-session agent task list (the ephemeral todo UI) is **scratch for the current task's steps
    only** — never a persistent store, and never mirrored into the issues.
  - Consolidate any scattered planning docs into the single source and retire/redirect the rest (leave
    a one-line pointer so old links resolve).

## Commit Messages

Never add Claude attribution lines anywhere: no Co-Authored-By trailers in commits, no "Generated with Claude Code" footer in PR descriptions, and no attribution in issues, comments, or reviews.

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

- **Ask about branch protection per project.** The first time you work in a repo, check its
  `AGENTS.md` for a recorded answer. If there is none, ask the user whether `main` should be
  protected. Record the answer in the repo's `AGENTS.md` under "SDLC working agreements" so later
  sessions do not ask again. If yes, never commit directly to `main`, and offer to turn on GitHub
  branch protection for it. If no, committing directly to `main` is allowed in that repo.
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

## Scripting Language

- **Prefer TypeScript over Python** for scripts, tooling, and glue code in any repo, unless an
  essential package is only available in Python or the particular task is almost always done in
  Python (e.g. data science notebooks, ML pipelines).

## Package Management

- **Prefer `pnpm`** when starting new JavaScript/TypeScript projects
- Use `pnpm init`, `pnpm add`, `pnpm install`, etc. instead of `npm` or `yarn`

## Security

- Make suggestions to fix insecure credential / secret storage and usage.
- Never read, log, print, or display `.env` files or any file containing secrets
- Do not commit credentials, tokens, or API keys — check `git diff --cached` before committing
- Sensitive files: `.env`, `.env.*`, `*.pem`, `*.key`, `*_rsa`, `*.p12`

## Deployment

- **Never deploy or publish on your own initiative.** Deploy/promote commands (`netlify deploy`, `vercel deploy`, `vercel --prod`, the Vercel/Netlify MCP deploy tools, etc.) run **only when the user explicitly asks** ("deploy", "push it live", "ship it").
- These commands are **auto-allowed in settings (no confirmation prompt)** so they work when the user is remote and can't approve a prompt. The absence of a prompt is **not** permission to deploy proactively — the discipline is on you.
- Default flow: edit → verify locally (open the file / preview) → **stop and wait** for an explicit deploy instruction. Don't redeploy after every small edit; repeated deploys waste paid hosting usage.

## Local CI Runner

Self-hosted GitHub Actions runners on this Mac are the default CI/CD compute. Tooling lives in
[`anthnyalxndr/local-ci-runner`](https://github.com/anthnyalxndr/local-ci-runner) (scripts symlinked onto `PATH`).

- **`t0k0n` org repos** run CI/CD on the local runner by default (`runs-on: ${{ vars.RUNNER_LABEL || 'self-hosted' }}`).
  Just commit and push as normal; watch results with `gh run watch` — no special handling.
- **Personal private repos (just-in-time):** when starting work on a **private** `anthnyalxndr/*` repo that uses
  GitHub Actions, check for a repo runner with `gh api repos/anthnyalxndr/<name>/actions/runners`. If none and
  the workflows target `self-hosted`, provision a **JIT ephemeral** runner (single-use per job, no sudo): `setup-local-runner jit anthnyalxndr/<name>`.
  **Never** do this for public repos (a fork PR can run arbitrary code on the machine).
- **Override (Mac off / traveling):** `runner-label cloud <org>` routes runs to GitHub-hosted cloud;
  `runner-label local <org>` switches back.

## Writing for humans

Applies to every piece of prose a person will read: chat replies, documents, reports, commit
messages, PR descriptions, issue text, comments in code. The full pattern list is the
`writing-for-humans` skill (`~/.claude/skills/writing-for-humans`, a fork of blader/humanizer
3.0.0 plus local rules 26-35); invoke it to rewrite or review existing text. Its
`scripts/prose_guard.py` counts the checkable subset over a file; a diagnostic, not a gate.

- Name the reader before you write. Use only words that reader already uses. If the source uses
  a code, label, or acronym the reader would not know, describe the thing instead. Name a field
  or label by its kind on first mention ("the Surface field"), in double quotes if it is an
  ordinary word that misreads (the "When" field); backticks only for identifiers that exist
  literally in code or data.
- One idea per sentence, about 20 words or fewer. Prefer a period to a dash, colon, or semicolon.
  No em-dashes or en-dashes anywhere, except an en-dash inside a number range.
- State the point directly. Do not announce it first ("Here is what matters", "The real question
  is") and do not close with a one-line restatement.
- Do not build sentences as "not X but Y" or "X rather than Y" unless the reader actually
  believes X. Do not rebut objections nobody has raised.
- Lists of three only when there are exactly three things. Do not pad or trim to three.
- Use a bulleted list only when the items are parallel. Otherwise write a paragraph.
- Bold only labels a reader scans for. Never bold a phrase for emphasis. No emojis, no warning
  glyphs, no horizontal rules.
- One hedge per claim at most, and only when you can say what the uncertainty is. Delete
  "simple", "just", "actually", "exactly", "truly", "useful" and other intensifiers.
- Use "is", "has", "does". Avoid "serves as", "features", "leverages", "robust", "pivotal",
  "landscape", "additionally", "crucial", "comprehensive", "holistic".
- Every claim must match the source you read. If simplifying a sentence would change what the
  source says, keep the distinction and say it plainly. Say when you have left something out.
- No greetings, no "I hope this helps", no offers of further help in standalone text.
- Write whole sentences with their articles and verbs. No arrows, no symbol shorthand, no
  abbreviation the reader would have to decode. A long sentence becomes two sentences, not a
  fragment.
- If a sentence could appear unchanged in another project's document, it says nothing about this
  one. Replace it with the mechanism, the number, or the instruction, or cut it.
- Headings in sentence case. A bold lead-in must be followed by detail it did not already state.
  Parentheses hold a short aside, never a list.
