# AGENTS.md

This file sits at the root of a **bare-repo dotfiles work tree** (`$HOME`). It applies
**only when you are creating, editing, or committing files tracked by the dotfiles repo**
(shell config, `~/.config/*`, `~/.zfunc/*`, `~/.zshrc`, etc.). If you are working on an
unrelated project under `$HOME` (e.g. anything in `~/Projects/`), **ignore everything below —
it does not apply to that work.**

## Working with the dotfiles repo

- The repo is **bare**: git dir `~/.dotfiles`, work tree `$HOME`. There is no `.git` in
  `$HOME`. Drive it with the `dotfiles` alias, never plain `git`:
  `dotfiles = git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"`
- **Stage changes with `dotfiles add -u`** (stages edits/deletes to tracked files only).
  **NEVER** run `dotfiles add -A` or `dotfiles add .` — the work tree is all of `$HOME`, so
  that would try to stage every file and nested git repo in the home directory.
- To onboard a **new** dotfile, add it by explicit path: `dotfiles add ~/.config/foo`.
  Do not auto-track new files; `status.showUntrackedFiles` is `no` by design.
- Commit with Conventional Commits (e.g. `docs(dotfiles): …`); do **not** add a
  `Co-Authored-By` trailer.
- There is **one `main` branch** for all machines. OS differences are handled at runtime via
  `~/.config/shell/os/$(uname)/` sourcing — do **not** create per-OS or per-host branches.
- Full model and rationale: see `~/README.md`.
