# Dotfiles Redesign — GNU Stow, single `main`, base + per-OS packages

**Date:** 2026-06-18
**Status:** Approved (design); pending implementation plan
**Repo:** `anthnyalxndr/dotfiles` (public) · local clone `~/dotfiles`

## Problem

The existing repo "was never set up properly." Two root-cause design choices made it
painful:

1. **Copy/rsync sync, not symlinks.** `install` rsyncs repo → `$HOME`; `update_dotfiles`
   copies `$HOME` → repo. Two manual directions ⇒ constant drift and silent divergence
   between `~/.zshrc` and the tracked file.
2. **One branch per environment** (`darwin`, `fedora`, `ubuntu_2204`, `ubuntu_2401`,
   `devcontainer`). No shared base, so a common change must be hand-replicated and merged
   across five branches. Measured divergence is dominated by *accidental drift* (files
   renamed on one branch only, files present on one branch and missing on another, tracked
   junk) rather than intentional per-OS configuration.

Secondary issues: `update_dotfiles` has real bugs (`is_ignored basename "$item"` passes the
literal string `basename`; references `Brewfile` while the file is `.Brewfile`, so
`rm Brewfile` fails); tracked junk (`.config/wireshark/*` incl. a 5,725-line `preferences`,
a binary `nnn` `.tar.gz`, editor lock files); `install` hardcodes `git checkout devcontainer`
and runs `chsh`/`git clone` non-idempotently.

**Security note:** A pre-design sweep of every tracked file across all five branches found
**no leaked secrets**. `.config/gh/hosts.yml` is tracked but contains no token (the `gh`
token lives in the macOS keyring). `env_variables` sets only paths. This redesign still
stops tracking `gh/hosts.yml` going forward as a precaution.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Management model | **GNU Stow** (symlink manager) |
| OS package scope | **`base` + `os-darwin` + `os-linux`**; per-distro package lists as data files |
| Git history | **Preserve `darwin` as the new `main`**; tag old branches as backups, then delete |
| Track `gh/hosts.yml`? | **No** (gitignore) |
| Track `nnn` binary `.tar.gz`? | **No** (remove) |

### Why Stow (vs chezmoi / bare repo / yadm)

- The repo stays a **self-contained leaf directory**, so the home directory's 30+ nested git
  repos (`~/.oh-my-zsh`, `~/.nvm`, `~/.tmux/plugins/tpm`, all of `~/Projects/*`) are
  irrelevant to it by construction — the nested-repo concern disappears. (Only the bare-repo
  / `$HOME`-as-work-tree model exposes that concern.)
- Symlinks give a **single source of truth** — editing `~/.zshrc` edits the repo file.
- Genuine per-OS differences are **small and already isolated** in `.config/shell/`
  (`path`, `homebrew_config`, `nvm`, `sdkman`, `go`), so no templating engine is needed.
- Maximum **transparency** — no `chezmoi edit`/`apply` indirection.
- `chezmoi` remains the documented fallback if heavy *within-file* per-OS differences or
  password-manager-backed secret templating become a real need.

## Architecture

### Repository layout (Stow packages)

A Stow *package* is a subdirectory whose internal tree is mirrored, via symlinks, into the
target dir (`$HOME`). Example: `base/.config/shell/aliases` → `~/.config/shell/aliases`.

```
~/dotfiles/
├── README.md
├── install.sh              # idempotent bootstrap
├── uninstall.sh            # stow -D, full reversal
├── Brewfile                # macOS packages (data, not stowed)
├── packages/
│   ├── apt.txt             # Debian/Ubuntu packages (data)
│   └── dnf.txt             # Fedora packages (data)
├── docs/superpowers/specs/ # this spec
├── base/                   # stowed on EVERY OS — shared config
│   ├── .zshrc .zprofile .profile .bashrc .bash_profile
│   ├── .config/shell/{aliases,env_variables,functions,go,nvm_config,nnn_config,shell_behavior}
│   ├── .config/git/{config,ignore,gitk,templates/hooks/pre-commit}
│   ├── .config/tmux/tmux.conf
│   ├── .config/zsh/{functions,oh_my_zsh}
│   ├── .zfunc/{_poetry,join_array,save_directory_stack.zsh,zhelp,READ_ME.md}
│   └── .cursor/{commands,rules}        # salvaged from devcontainer branch
├── os-darwin/              # stowed only on macOS
│   └── .config/shell/os/darwin/homebrew   # brew shellenv + PATH (from homebrew_config)
└── os-linux/               # stowed only on Linux
    └── .config/shell/os/linux/…           # linuxbrew / PATH tweaks, if any
```

### OS-conditional sourcing (no branches, no templating)

`.profile` keeps its existing module sourcing and gains one OS-aware loop at the end, so a
**single shared `.profile`** works everywhere:

```bash
OS="$(uname | tr '[:upper:]' '[:lower:]')"   # → darwin / linux
if [ -d "$SHELL_CONFIG/os/$OS" ]; then
  for f in "$SHELL_CONFIG/os/$OS"/*; do [ -r "$f" ] && source "$f"; done
fi
```

`homebrew_config` (currently macOS-only) moves into `os-darwin/.config/shell/os/darwin/`.
This loop plus per-OS package selection is the entire multi-OS mechanism.

### `install.sh` (idempotent bootstrap)

- Detect OS via `uname` → select `os-darwin` or `os-linux`.
- `stow --no-folding --target="$HOME" base <os-pkg>`.
  - **`--no-folding` is required**: it forces real directories and leaf-file symlinks so
    multiple packages can co-populate shared dirs like `~/.config/shell`, and Stow never
    folds a whole directory into one symlink — guaranteeing unmanaged files in `~/.config`
    are never swallowed.
- Optional `--packages` flag installs OS dependencies: `brew bundle --file=Brewfile` on
  macOS; `apt`/`dnf` from `packages/*.txt` on Linux.
- All post-install steps guarded for idempotency:
  - `[ -d ~/.oh-my-zsh ] || git clone …`
  - `[ -d ~/.tmux/plugins/tpm ] || git clone …`
  - `chsh -s "$(command -v zsh)"` only if `$SHELL` is not already zsh.
- Re-runnable anytime; use `stow -R` to re-link after changes.

### `uninstall.sh`

`stow -D --target="$HOME" base <os-pkg>` removes every managed symlink cleanly — the
reversibility the copy-based setup lacked.

## Cleanup performed during migration

- **Delete tracked junk:** `.config/wireshark/*` (8 files), `.config/nnn/plugins-*.tar.gz`
  (binary blob), any `.~lock.config#`, `.DS_Store`.
- **Stop tracking** `.config/gh/hosts.yml` and `.config/gh/config.yml` (machine/account
  state, not portable config; future leak risk in a public repo) → add to `.gitignore`.
- **Replace `.gitignore`**: drop the fragile `*` + ~40-line allowlist in favor of a normal
  denylist, since the repo is now a curated leaf dir of packages. Ignore `.DS_Store`,
  editor lock files, the gh state files, and binary blobs.

## Git history migration (preserve `darwin`)

1. Tag backups of all five branches and push them — nothing is lost:
   `archive/darwin`, `archive/fedora`, `archive/ubuntu_2204`, `archive/ubuntu_2401`,
   `archive/devcontainer`.
2. Build `main` from `darwin`; restructure into packages using `git mv` to preserve
   per-file history.
3. Salvage genuinely-useful per-OS bits into the new structure:
   `apt_package_list.txt` → `packages/apt.txt`; real Linux path tweaks → `os-linux`;
   `.cursor/` commands/rules from `devcontainer` → `base`.
4. Set the GitHub default branch to `main`; delete the five old branches (safe — backed up
   as tags).

## Verification (before claiming done)

- `stow -n -v --no-folding base os-darwin` (dry run) → confirm zero unexpected conflicts.
- After stow: `readlink ~/.zshrc` resolves into the repo; `zsh -ic exit` loads with no
  errors sourcing.
- `uninstall.sh` fully removes links and leaves no orphans; re-running `install.sh` proves
  idempotency.
- (Optional) CI smoke test in a Linux container exercises `os-linux`.

## Out of scope

- Migrating to `chezmoi` (documented fallback only).
- Per-distro split of `os-linux` into `os-fedora`/`os-ubuntu` (diffs don't justify it today).
- Secret management tooling (no secrets are tracked).
