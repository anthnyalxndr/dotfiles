# Local CI/CD Runner — Design Spec

- **Date:** 2026-06-29
- **Status:** Approved design, ready for implementation planning
- **Author:** anthnyalxndr (with Claude)
- **Spec home:** dotfiles repo (`~/docs/superpowers/specs/`, work tree `$HOME`)

## 1. Goal

Make CI/CD work execute on a **self-hosted GitHub Actions runner on this Mac** by
default — for both interactive development and agent-driven development — instead of
GitHub-hosted cloud runners. Self-hosted runner minutes are free, keep compute local,
and remove the Actions-minutes pressure that currently shapes a deliberately minimal CI.

## 2. Scope

In scope (now):

- **`t0k0n` org → one org-level runner** on the Mac, covering `tokon-www` and
  `payload-mui-starter` (and future t0k0n repos), scoped via a runner group.
- **Personal `anthnyalxndr/*` private repos → repo-level runner, provisioned
  just-in-time** by agents per a global `~/.claude/CLAUDE.md` instruction.
- **Full CI + CD on the runner**, with a runner override (local ⇄ GitHub-hosted cloud).
- A reusable `setup-local-runner` script in the dotfiles repo as the provisioning primitive.
- Copier-template changes so new scaffolded repos adopt the pattern.

Out of scope (now):

- The other orgs (`High-Pass-Education`, `ata-forks`, `ata-python`) — ignored for now;
  the design is structured so adding them later is a one-command repeat.
- The ~50 legacy personal repos — left alone; opt-in only via the JIT path.
- Migrating repos between accounts/orgs. No mass reorganization.
- Upgrading any org's GitHub plan (decision: stay on **free**).

## 3. Key constraints discovered (verified against GitHub/Vercel docs, 2026)

These shaped the design and overrode initial assumptions. Plan context: `anthnyalxndr`
is a **personal User account** (cannot host org-level runners — repo-level only); `t0k0n`
is a **free org** with **private** repos.

| # | Constraint | Source |
|---|-----------|--------|
| C1 | A personal user account supports **repo-level runners only** — no account-wide runner. Org runners require an actual org. | docs.github.com/actions/.../add-runners |
| C2 | **Org-level variables & secrets are NOT accessible by private repos on GitHub Free.** ⇒ the override switch must be a **repository** variable, not an org variable. | "Store information in variables" |
| C3 | **Free private repos cannot create environments at all** (no environment secrets, no required-reviewer approval gate). Even Pro/Team does not add required-reviewers on private repos — only Enterprise. ⇒ deploy gate = **`workflow_dispatch`-only**; deploy secrets = **repository secrets**. | docs.github.com environments / deployments |
| C4 | **Self-hosted runner groups DO work on free orgs** (the Team/Enterprise gate is for GitHub-*hosted* larger runners). ⇒ we can scope the t0k0n runner to selected repos. | "Managing access to self-hosted runners using groups" |
| C5 | `runs-on: ${{ vars.RUNNER_LABEL || 'self-hosted' }}` is valid; an **unset var resolves to empty string**, so the `|| 'self-hosted'` fallback is mandatory. | "Choosing the runner for a job" |
| C6 | Registering an **org** runner needs `admin:org` scope (current `gh` token has `read:org` only → `gh auth refresh -s admin:org`). A **repo** registration token needs `repo` scope (already present). Registration tokens expire after **1 hour**. | REST: self-hosted-runners |
| C7 | macOS runner service is a **LaunchAgent** (`svc.sh install`) — needs a **GUI login session**; will not run pre-login on an unattended reboot (auto-login fixes it). `svc.sh install` typically needs `sudo`. | actions/runner darwin.svc.sh |
| C8 | Service runs with a **minimal launchd environment** — Homebrew (`/opt/homebrew/bin`), mise/asdf shims, corepack/pnpm, `uv` are invisible unless wired in. Inject via **`.path`** (overwrites PATH wholesale — must include base dirs) and **`.env`** (literal `KEY=VALUE`, no shell expansion). | actions/runner docs |
| C9 | Self-hosted runner + **public** repo = fork-PR RCE risk. **Private repos only.** Drive deploys from `workflow_dispatch` (never `pull_request`/`pull_request_target`). | "Security hardening for self-hosted runners" |
| C10 | Vercel auto-deploys every push via Git integration; a CLI deploy on the same commit **double-deploys**. Disable via `vercel.json` `{"git":{"deploymentEnabled":false}}` (all plans). | Vercel Git Configuration |

## 4. Architecture

```
                    ┌───────────────────────────── YOUR MAC ─────────────────────────────┐
                    │                                                                     │
  t0k0n org ────────┼─► runner: ~/actions-runners/org-t0k0n/   (launchd LaunchAgent svc)  │
  (org runner,      │     labels: self-hosted, macOS, ARM64                               │
   runner group     │     toolchain wired via .path/.env                                  │
   → selected repos)│                                                                     │
                    │                                                                     │
  anthnyalxndr/<x>  ┼─► runner: ~/actions-runners/repo-anthnyalxndr-<x>/  (JIT, private)  │
  (repo runner,     │     provisioned by agent via setup-local-runner                     │
   JIT, private)    │                                                                     │
                    │                                                                     │
                    │  shared primitives:  setup-local-runner  ·  runner-label (flip)     │
                    └─────────────────────────────────────────────────────────────────────┘

INNER LOOP (you or agent):  edit → commit → push branch
  └─► GitHub evaluates ci.yml → dispatches job to the matching runner on your Mac
        └─► lint · typecheck · test · docs:check   (host toolchain via .path)
              └─► results as checks → `gh run watch` / `gh pr checks`  (agent sees transparently)

DEPLOY (explicit, never automatic):  `gh workflow run cd.yml`  (manual only)
  └─► vercel pull → build --prod → deploy --prebuilt --prod   (on local runner)

OVERRIDE (Mac off / traveling):  set repo var RUNNER_LABEL=ubuntu-latest  (per-repo, or flip-script)
  └─► subsequent runs (CI and CD) execute on GitHub-hosted cloud; Vercel stays the deploy target
```

### Components

1. **Runner installs** — one directory per registration scope under `~/actions-runners/`
   (the runner binary is single-target). Each registered as a launchd LaunchAgent service.
2. **`setup-local-runner`** (dotfiles, on `PATH`) — the provisioning primitive.
   Subcommands: `org <org>` · `repo <owner/name>` · `list` · `remove <scope>`.
3. **`runner-label`** (dotfiles) — the override flip-script: sets/clears the `RUNNER_LABEL`
   repo variable across a set of repos (the kill-switch, since C2 rules out an org var).
4. **Workflow templates** (copier) — `ci.yml` (push/PR) and `cd.yml` (manual), both using
   the `RUNNER_LABEL` override expression.
5. **Global `~/.claude/CLAUDE.md` note** — the JIT provisioning instruction for agents.

## 5. `setup-local-runner` script

A single idempotent script that does the full dance for either scope.

**`setup-local-runner org <org>`** and **`setup-local-runner repo <owner/name>`:**

1. **Safety check** — refuse if the target repo is **public** (C9): `gh repo view --json
   visibility`. For `org`, verify the org's repos that will use the runner are private
   (or rely on the runner-group selected-repos policy).
2. **Idempotency** — if a runner for this scope is already registered and the local dir
   exists, no-op (or offer `--force` re-register).
3. **Download** the runner tarball into `~/actions-runners/<scope>/` (pin a version).
4. **Mint a registration token** via `gh api` (C6): `POST
   /orgs/{org}/actions/runners/registration-token` (needs `admin:org`) or
   `POST /repos/{owner}/{repo}/actions/runners/registration-token` (needs `repo`).
5. **Configure** — `config.sh --url <...> --token <...> --labels self-hosted,macOS,ARM64
   --unattended --name <host>-<scope> [--runnergroup <group>]`.
6. **Wire the toolchain** (C8) — write `.path` with the full PATH
   (`/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` + mise/asdf/pnpm dirs)
   and `.env` with any literal env (`HUSKY=0`, etc.).
7. **Install the service** — `sudo ./svc.sh install <user>` then `./svc.sh start` (C7).
8. **Verify** — `./svc.sh status`; confirm the runner shows online in `gh api .../runners`.

`list` enumerates installed runners + service status; `remove` stops/uninstalls the
service, mints a remove-token, deregisters, and deletes the directory.

## 6. Toolchain wiring (C8)

- **`.path`** (in each runner dir) sets the job PATH and **overwrites it wholesale** — must
  include base system dirs *plus* Homebrew/mise/pnpm/uv, or core tools vanish.
- **`.env`** holds literal `KEY=VALUE` only (no `$PATH` expansion). Use it for `HUSKY=0`,
  `NEXT_TELEMETRY_DISABLED=1`, etc.
- Either change requires `./svc.sh stop && ./svc.sh start`.
- Workflows may still use `pnpm/action-setup` + `actions/setup-node` for **version pinning**
  (they work on self-hosted); the `.path` wiring is the floor that makes the runner usable
  even for steps that assume host tools.

## 7. Workflow design

### 7.1 Override mechanism

- **Repository variable `RUNNER_LABEL`** (C2). Default: unset → expression falls back to
  `self-hosted`. Set to `ubuntu-latest` to route a repo's runs to GitHub-hosted cloud.
- **`runner-label` flip-script** — `runner-label cloud t0k0n` / `runner-label local t0k0n`
  loops `gh variable set/delete RUNNER_LABEL --repo t0k0n/<each>`; this is the kill-switch.
- **Per-run override** — a `workflow_dispatch` `runner` **choice** input
  (`self-hosted` | `ubuntu-latest`), combined as
  `runs-on: ${{ inputs.runner || vars.RUNNER_LABEL || 'self-hosted' }}`.
  (No non-empty `default:` on the input, or the `||` fallback becomes unreachable — C5.)

### 7.2 `ci.yml`

- Triggers: `push` to any branch **and** `pull_request` into `main` (free local minutes
  remove the prior PR-only constraint).
- `runs-on: ${{ vars.RUNNER_LABEL || 'self-hosted' }}`.
- `concurrency: { group: ci-${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }`.
- Steps: checkout (clean) → pnpm/node setup (pinned) → install → lint → typecheck →
  `docs:check` → test. Same checks already in `payload-mui-starter/ci.yml`.

### 7.3 `cd.yml`

- Trigger: **`workflow_dispatch` only** (C3) — never on push. Satisfies "never deploy on
  own initiative": deploy fires only when a human (write access = you) runs it.
- `runs-on: ${{ inputs.runner || vars.RUNNER_LABEL || 'self-hosted' }}`.
- Secrets: **repository secrets** `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` (C3).
- Steps: `vercel pull --yes --environment=production` → `vercel build --prod` →
  `vercel deploy --prebuilt --prod` (build happens on the runner).
- Vercel double-deploy avoidance (C10): set `vercel.json`
  `{"git":{"deploymentEnabled":false}}` so CI owns production deploys. (First commit
  carrying the config may still auto-deploy once — establish it deliberately.)
- Optional belt-and-suspenders: a `confirm` text input that must equal a known value.

## 8. Security model

- **Private repos only** (C9); the `setup-local-runner` safety check enforces it for the
  JIT path. Public personal repos (`dotfiles`, `gtm_v2`, `caching_proxy`, …) never get a runner.
- **Runner group** for t0k0n (C4): default group scoped to selected repositories (or a
  dedicated `local-mac` group), restricting which repos can target the runner.
- **Fork-PR policy** on; workflows use `pull_request` (read-only token, no secrets), never
  `pull_request_target`. Deploys are `workflow_dispatch`-only.
- **Secrets** are repository secrets, never written to the runner filesystem.
- **Persistent runner** with a **clean checkout per run**; periodic `_work` cleanup to limit
  state leak. (Ephemeral isn't a clean single-Mac service pattern — C7/runner findings.)

## 9. Agent integration

- **Transparent execution** — agents commit and push as normal; the runner picks up the job;
  agents observe results via `gh run watch` / `gh pr checks`. No special agent wiring for t0k0n.
- **JIT provisioning for personal repos** — add to global `~/.claude/CLAUDE.md` (committed
  via the `dotfiles` alias):

  > **Local CI runner (personal repos):** When you begin work on a **private**
  > `anthnyalxndr/*` repo that uses GitHub Actions, check whether a repo-level self-hosted
  > runner is registered (`gh api repos/anthnyalxndr/<name>/actions/runners`). If none and
  > the repo's workflows target `self-hosted`, provision one with
  > `setup-local-runner repo anthnyalxndr/<name>`. **Never** do this for public repos.

- **Deterministic alternative (noted, not chosen):** a Claude Code hook (via the
  `update-config` skill) could guarantee the check runs every session. The CLAUDE.md note
  was chosen per user preference; the hook remains an upgrade path.

## 10. Copier-template changes

- `template/.github/workflows/{ci.yml}.jinja` → `runs-on: ${{ vars.RUNNER_LABEL || 'self-hosted' }}`.
- Add a `cd.yml.jinja` template (manual-gated Vercel deploy) behind a copier question.
- New copier questions: `use_local_runner` (bool), deploy target/`deploy_via_ci` (bool).
- **The fallback literal is set by `use_local_runner`** to avoid a hang-on-`self-hosted`
  footgun: the template renders `runs-on: ${{ vars.RUNNER_LABEL || '<fallback>' }}` where
  `<fallback>` = `self-hosted` when `use_local_runner` is true (repo is expected to have a
  runner) and `ubuntu-latest` otherwise. `RUNNER_LABEL` then overrides either way. This
  means a scaffolded repo never queues forever waiting on a runner it doesn't have; a
  local-runner repo only needs `setup-local-runner` run once before its first push.

## 11. t0k0n bring-up sequence

1. `gh auth refresh -h github.com -s admin:org` (C6).
2. Create/scope a runner group (or set default group → selected repos) for t0k0n (C4).
3. `setup-local-runner org t0k0n`.
4. For each t0k0n repo that should default to local: ensure `ci.yml`/`cd.yml` use the
   `RUNNER_LABEL` expression; add repo secrets for CD; set `vercel.json`
   `git.deploymentEnabled:false` where CD is owned by CI.

## 12. Validation plan

1. Register the t0k0n org runner; confirm **online** in `gh api orgs/t0k0n/actions/runners`.
2. Push a throwaway branch to `payload-mui-starter`; confirm the job runs on the Mac
   (runner name in `gh run view`), and toolchain steps resolve `pnpm`/`node`/`uv`.
3. `runner-label cloud t0k0n` → push again → confirm the run lands on `ubuntu-latest`;
   `runner-label local t0k0n` → confirm it returns to the Mac.
4. Trigger `cd.yml` via `gh workflow run`; confirm a single Vercel production deploy (no
   double-deploy) and that no push auto-triggered it.
5. Run `setup-local-runner repo anthnyalxndr/<one-private-repo>`; confirm the safety check
   rejects a public repo.

## 13. Decisions log

- **Execution:** self-hosted GitHub Actions runner (not `act`, not hook-only).
- **Scope:** t0k0n org runner now; personal repos JIT via CLAUDE.md note; other orgs later.
- **Agent model:** transparent execution + JIT provisioning note.
- **CI+CD:** both local by default; CD manual-gated; `RUNNER_LABEL` override + flip-script.
- **Plan:** stay free → repo variables, `workflow_dispatch` gating, repo secrets.
- **Lifecycle:** persistent runner, launchd LaunchAgent, toolchain via `.path`/`.env`.

## 14. Open items for the implementation plan

- Exact script home in dotfiles (`.zfunc/` vs a tracked `~/.local/bin/`) and the runner
  version-pin strategy.
- Whether `payload-mui-starter` should adopt `push`-trigger CI immediately or stay PR-only.
- `tokon-www` is currently docs-only — CD wiring for it waits until it has an app; the
  pattern is defined here and applies when it does.
- Confirm the Mac's toolchain manager (Homebrew/corepack/mise?) to fill the exact `.path`.

## 15. References

GitHub: add self-hosted runners; REST self-hosted-runners (registration tokens, scopes);
choosing the runner for a job (`runs-on` expressions, label AND-semantics); store
information in variables (org-var private-repo Free restriction); environments &
deployments (plan gating); managing access to self-hosted runners using groups; security
hardening for self-hosted runners. Vercel: CLI (`pull`/`build`/`deploy --prebuilt`); Git
configuration (`git.deploymentEnabled`). Payload: storage adapters & Postgres on Vercel
(serverless constraints).
