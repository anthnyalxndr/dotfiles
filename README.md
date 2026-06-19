# dotfiles

Personal dotfiles, managed with a **bare git repository**: the git database lives in
`~/.dotfiles` and the *work tree* is `$HOME` itself. Files are tracked as **real files in
place** — there are no symlinks and no copy/sync step.

---

## Why a bare repo (and not symlinks)

The common alternatives and why this repo doesn't use them:

- **Copy/rsync into `$HOME`** (the old setup): edits drift between the repo and `$HOME`
  because you must manually sync in both directions. Avoided.
- **Symlinks (e.g. GNU Stow):** `~/.zshrc` becomes a link into a repo dir. Clean, but it has
  one failure mode that matters here — **atomic-save clobber**. Many programs (and AI
  agents/editors) save a file by writing a temp file and `rename()`-ing it over the
  original. `rename()` *replaces the symlink with a regular file*, silently severing the link
  to the repo. The edit lands in `$HOME`, the repo goes stale, and you don't notice. Because
  files here are edited by tools and agents that do exactly this, symlinks were rejected.
- **Bare repo (this setup):** files are real files in `$HOME`. Any write — by hand, by a
  tool, or by an agent — is just a normal change that shows up as a diff in `dotfiles status`.
  Nothing breaks, nothing drifts silently.

The trade-off accepted: you drive git through a `dotfiles` alias (not plain `git`), you must
add files explicitly, and a fresh-machine checkout needs a small backup step. See below.

---

## How a bare repo differs from a standard repo

### Standard repo
The git database lives **inside** the work tree as a `.git/` folder. In `~/project`, git
finds `~/project/.git` and infers "the work tree is the folder containing `.git`." You `cd`
in and run `git`. The repo is a self-contained folder you can browse or delete as a unit.

### Bare-repo dotfiles trick
You **separate the git database from the work tree**. The database goes in a side folder
(`~/.dotfiles`), and it is pointed at `$HOME` as its work tree. Because there is **no `.git/`
in `$HOME`**, your home directory never *becomes* a normal repo — which is the whole reason
it doesn't collide with the many other git repos that live under `$HOME` (`~/.oh-my-zsh`,
`~/.nvm`, `~/.tmux/plugins/tpm`, everything under `~/Projects/`, etc.).

It's wired together with an alias that pre-fills the two locations:

```sh
alias dotfiles='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
```

So `dotfiles` *is* `git`, just told where its database (`~/.dotfiles`) and work tree
(`$HOME`) are. This alias is defined in `~/.config/shell/dotfiles_alias` and sourced by
`~/.profile`.

### Side-by-side

| | Standard repo | This bare-repo setup |
|---|---|---|
| Git command | `git …` | `dotfiles …` (the alias) |
| Where you run it | `cd` into the repo first | anywhere — work tree is always `$HOME` |
| Staging files | `git add .` is fine | **only** `dotfiles add <file>` — never `dotfiles add -A`/`.` |
| `… status` | shows the repo | needs `status.showUntrackedFiles=no`, else it lists *all* of `$HOME` |
| The repo as a place | a browsable, deletable folder | intermingled with your real home dir |
| New machine | `git clone url ~/project` | clone `--bare`, then `dotfiles checkout` (back up conflicts first) |
| Files in `$HOME` | n/a | the actual tracked files, edited in place |

### Things to internalize

- **`status.showUntrackedFiles=no` is essential.** The work tree is your entire home dir, so
  without it `dotfiles status` would list thousands of untracked files. With it, only files
  you've explicitly added show up — and your other repos under `$HOME` stay invisible.
- **You lose `git status` as a "new untracked file" signal.** You must *remember* to
  `dotfiles add` each new dotfile you want tracked.
- **The footgun is `dotfiles add .` / `dotfiles add -A`** near a nested repo or a big
  directory. Plain `git` typed by mistake in `$HOME` is harmless (no `.git` there, so it just
  errors) — the danger is specifically the `dotfiles` alias plus a wildcard add. Always add
  explicit paths.
- **Nested repos are not submodules.** git won't recurse into another repo's `.git`; with
  `showUntrackedFiles=no` those repos are simply invisible. Just never `dotfiles add` inside
  them.

---

## Bootstrap a new machine

```sh
curl -fsSL https://raw.githubusercontent.com/anthnyalxndr/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
# or, after the repo is checked out: ~/.config/dotfiles/bootstrap.sh
```

`bootstrap.sh` clones the repo bare into `~/.dotfiles`, sets `showUntrackedFiles=no`, and
checks the files out into `$HOME`. If files already exist (e.g. a default `~/.bashrc`), the
checkout would refuse to overwrite them — the script automatically moves the conflicting
files into `~/.dotfiles-backup-<timestamp>/` and retries, so nothing is lost.

After it runs, open a new shell — the `dotfiles` alias loads via
`~/.config/shell/dotfiles_alias`.

---

## Daily workflow

```sh
dotfiles status                 # what changed (only tracked files appear)
dotfiles add -u                 # stage ALL edits/deletes to already-tracked files (the common case)
dotfiles add ~/.zshrc           # onboard a NEW file — use its full path, NEVER `dotfiles add -A`/`.`
dotfiles commit -m "..."        # commit
dotfiles push                   # publish to GitHub
dotfiles diff                   # review pending changes
```

**Use `dotfiles add -u` for the everyday case** — committing changes to files already under
management. The `-u` flag stages modifications and deletions of *tracked* files only; it
**cannot** accidentally pull in untracked files, junk, or nested repos, which makes it the
safe choice for scripts/cron too. Reserve an explicit path (`dotfiles add ~/.foo`) for the
deliberate act of onboarding a brand-new dotfile.

An agent or tool editing a tracked file just shows up as a diff in `dotfiles status` — no
broken links, no silent drift. Review and `dotfiles commit` it like any other change.

---

## OS differences (no branches)

`~/.profile` sources the shared `~/.config/shell/*` modules, then any modules under
`~/.config/shell/os/$(uname | tr A-Z a-z)/` (`darwin` or `linux`). All OS files are tracked
and present on every machine; only the matching OS directory is sourced at runtime. This
replaces the old branch-per-OS scheme — there is a single `main` branch for all machines.

```bash
OS="$(uname | tr '[:upper:]' '[:lower:]')"     # darwin / linux
if [ -d "$SHELL_CONFIG/os/$OS" ]; then
  for f in "$SHELL_CONFIG/os/$OS"/*; do [ -r "$f" ] && source "$f"; done
fi
```

Per-OS package installs are driven from the manifests below, not from git branches.

---

## Machine-local overrides

For anything machine-specific or secret — a per-host alias, a token, a path that exists on
only one box — use `~/.config/shell/local`. It is **untracked** (gitignored) and sourced
*last* by `~/.profile`, so it overrides the shared modules and never reaches the public repo:

```sh
# ~/.config/shell/local  (not committed)
alias wake_box='wakeonlan aa:bb:cc:dd:ee:ff'
export SOME_TOKEN=…
```

---

## Layout

- `~/.config/shell/` — shared shell modules, `os/{darwin,linux}/` for OS-specific bits,
  `dotfiles_alias` (defines the `dotfiles` alias), and an untracked `local` for
  machine-specific/secret overrides.
- `~/.config/{git,tmux,zsh}/`, `~/.zfunc/`, `~/.cursor/{commands,rules}` — tool config.
- `~/.config/dotfiles/` — repo tooling and package manifests: `bootstrap.sh`,
  `Brewfile`, `packages/apt.txt`, `packages/dnf.txt`.
- `~/README.md`, `~/AGENTS.md`, `~/CLAUDE.md` — kept at `$HOME` root (GitHub renders the
  README there; agents discover `AGENTS.md`/`CLAUDE.md` there).

## Recovering archived branches

The previous per-OS branches were deleted from GitHub but preserved as tags
(`archive/darwin`, `archive/fedora`, `archive/ubuntu_2204`, `archive/ubuntu_2401`,
`archive/devcontainer`, and `archive/stow-migration` — the abandoned GNU Stow approach).
To inspect one: `dotfiles checkout -b restore archive/fedora`.
