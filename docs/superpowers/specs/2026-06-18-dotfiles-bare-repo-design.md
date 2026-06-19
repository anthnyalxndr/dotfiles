# Dotfiles Redesign — Bare Git Repo (`$HOME` work tree), single `main`

> **Historical record.** Written during the migration. Two things changed afterward: the
> git alias was renamed `config` → `dotfiles` (defined in `~/.config/shell/dotfiles_alias`),
> and repo tooling moved under `~/.config/dotfiles/` (`bootstrap.sh`, `Brewfile`, `packages/`).
> For the current setup see `~/README.md`; read any `config …` command below as `dotfiles …`.

**Date:** 2026-06-18
**Status:** Approved (design); supersedes the Stow design of the same date
**Repo:** `anthnyalxndr/dotfiles` (public) · bare git dir at `~/.dotfiles`

## Why this supersedes the Stow design

The Stow design was fully built on `feat/stow-migration` (unpushed) and verified, then
the approach was reconsidered. **Decisive factor:** files are edited not only by humans but
by *agents and tools that save via atomic rename* (`write temp → rename() over original`).
A `rename()` replaces a **symlink** with a regular file, silently severing the link to the
repo and reintroducing drift. The bare-repo model stores **real files in place**, so any
such write is just a visible diff in `config status` — nothing breaks. This directly
addresses the owner's concern ("an agent will replace one of these files at some point").

The Stow branch is abandoned (never pushed); this branch (`feat/bare-repo`) is built fresh
from `darwin` to preserve history.

## Problem (unchanged)

Original repo was copy/rsync-based with one branch per OS, causing constant drift and
forcing common changes to be hand-replicated across five branches. Measured cross-branch
divergence was dominated by accidental drift and tracked junk, not intentional per-OS
config. Security sweep across all five branches found **no leaked secrets**
(`gh/hosts.yml` has no token — it lives in the macOS keyring).

## Decisions (locked)

| Decision | Choice |
|---|---|
| Management model | **Bare git repo**, git dir `~/.dotfiles`, work tree `$HOME` |
| Untracked-file handling | `status.showUntrackedFiles=no` + explicit `config add <file>` only |
| OS differences | Branchless: OS-conditional sourcing in `.profile` (`~/.config/shell/os/$OS/*`) |
| Git history | Preserve `darwin` as the new `main`; archive-tag + delete old branches |
| Track `gh/hosts.yml`? | No (gitignore) |
| Track `nnn` binary `.tar.gz`? | No (remove) |

### Why bare repo over symlinks/chezmoi here

- **No symlinks** → no atomic-rename clobber; tool/agent edits land as real, visible diffs.
- **No `.git` in `$HOME`** → home does not *become* a repo, so the 30+ nested repos
  (`~/.oh-my-zsh`, `~/.nvm`, `~/.tmux/plugins/tpm`, `~/Projects/*`) don't collide with it.
- **Git-native** → normal `git` mental model via a `config` alias; `config status` surfaces
  any change to a tracked file (the desired safety net for agent edits).
- Accepted trade-offs: must use `config` (not `git`) from `$HOME`; must `config add`
  explicitly (never `-A`/`.`); fresh-machine checkout needs a backup-on-conflict step.

## Architecture

### The bare-repo mechanism

```sh
git init --bare $HOME/.dotfiles                     # database only, no work tree of its own
alias config='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
config config --local status.showUntrackedFiles no  # hide all of $HOME's untracked files
```

`config` is `git` with the git dir (`~/.dotfiles`) and work tree (`$HOME`) pre-set. Files
are tracked at home-relative paths (`.zshrc`, `.config/shell/aliases`). There is **no
`.git/` in `$HOME`**, so other repos under `$HOME` are unaffected, and plain `git` typed in
`$HOME` is inert (no repo found) — the only footgun is `config add .`/`-A`, which the
workflow forbids.

### Tracked layout (home-relative)

```
~/.zshrc ~/.zprofile ~/.profile ~/.bashrc ~/.bash_profile ~/.bash_completion
~/.gitignore                                   # ignores ~/.dotfiles + junk
~/.config/shell/{aliases,env_variables,functions,go,nvm_config,nnn_config,shell_behavior}
~/.config/shell/config_alias                   # defines the `config` alias (sourced)
~/.config/shell/os/darwin/homebrew             # macOS brew shellenv (from homebrew_config)
~/.config/shell/os/linux/path                  # linuxbrew/PATH (if present)
~/.config/git/{config,ignore,gitk}
~/.config/tmux/tmux.conf
~/.config/zsh/{functions,oh_my_zsh}
~/.config/1Password/ssh/agent.toml
~/.zfunc/{_poetry,join_array,save_directory_stack.zsh,zhelp,READ_ME.md}
~/.cursor/{commands,rules}                      # salvaged from devcontainer branch
~/Brewfile ~/packages/apt.txt ~/packages/dnf.txt
~/bootstrap.sh ~/README.md
```

### OS-conditional sourcing (no branches, no templating)

`.profile` sources the shared `~/.config/shell/*` modules, then any modules under
`~/.config/shell/os/$(uname|tr A-Z a-z)/`. All OS files are tracked and present on every
machine; only the matching OS dir is sourced at runtime:

```bash
OS="$(uname | tr '[:upper:]' '[:lower:]')"   # darwin / linux
if [ -d "$SHELL_CONFIG/os/$OS" ]; then
  for f in "$SHELL_CONFIG/os/$OS"/*; do [ -r "$f" ] && source "$f"; done
fi
```

### `bootstrap.sh` (fresh machine)

```sh
git clone --bare <url> $HOME/.dotfiles
config config --local status.showUntrackedFiles no
config checkout           # if it fails, back up the listed pre-existing files, then retry
```
The script automates the backup-on-conflict dance and prints the next step (ensure the
`config` alias is loaded — it ships in `~/.config/shell/config_alias`, sourced by `.profile`).

## Cleanup during migration

- Delete tracked junk: `.config/wireshark/*`, `.config/nnn/plugins-*.tar.gz`, lock files,
  `.DS_Store`.
- Stop tracking `.config/gh/hosts.yml` + `config.yml` (account/machine state) → gitignore.
- Replace the `*`+allowlist `.gitignore` with a denylist that also ignores `~/.dotfiles`.
- Remove legacy `install` / `update_dotfiles` scripts.
- Move dead `homebrew_config` → `.config/shell/os/darwin/homebrew` (sourced via the OS loop).

## Git history migration (preserve `darwin`)

1. Archive-tag all five branches (`archive/darwin` … `archive/devcontainer`) and push tags.
2. Promote `feat/bare-repo` to `main`; push.
3. Set GitHub default branch to `main`.
4. Delete the five old remote branches (recoverable via the archive tags).

## Verification

- **Sandbox:** init a bare repo with `--work-tree=<tmpdir>`, checkout the branch, assert
  files materialize as **regular files** (not symlinks), and `.profile` sources cleanly.
- **Live:** after checkout into `$HOME`, `config status` is clean; `readlink ~/.zshrc` shows
  it is a regular file (no symlink); `zsh -ic exit` loads with no errors; editing a tracked
  file shows up in `config status` (confirms the no-clobber property).

## Out of scope

- Symlink/Stow and chezmoi (documented alternatives only).
- Per-distro split of `os/linux` (`fedora` vs `ubuntu`) — diffs don't justify it.
- Secret management tooling (no secrets tracked).
