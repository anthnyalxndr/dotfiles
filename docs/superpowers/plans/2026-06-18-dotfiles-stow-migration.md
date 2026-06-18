# Dotfiles Stow Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the copy/rsync, branch-per-OS dotfiles repo into a GNU Stow setup with a single `main` branch, a shared `base` package, and `os-darwin`/`os-linux` packages.

**Architecture:** Repo stays a self-contained leaf directory at `~/dotfiles`. Files are organized into Stow packages whose trees mirror into `$HOME` via leaf-level symlinks (`stow --no-folding`). OS differences are handled by stowing the matching `os-*` package and an OS-aware sourcing loop in `.profile` — no branches, no templating. The current `darwin` branch becomes `main` with history preserved.

**Tech Stack:** GNU Stow, bash, git. No build system or test framework — verification is via `stow -n` dry runs and sandbox-`$HOME` smoke tests.

**Working branch:** `feat/stow-migration` (already created from `origin/darwin`).

**Safety model:** Phases A–B only touch `~/dotfiles` (zero risk to the live environment). Phase C mutates the live `$HOME` and Phase D mutates the GitHub remote — both are explicit checkpoints requiring confirmation, and both are made reversible (backup dir / archive tags) before any destructive step.

---

## File Structure

| Path | Responsibility |
|---|---|
| `base/` | Shared dotfiles stowed on every OS (shell, git, tmux, zsh, zfunc, cursor) |
| `os-darwin/.config/shell/os/darwin/homebrew` | macOS Homebrew `shellenv` (PATH/MANPATH) |
| `os-linux/.config/shell/os/linux/path` | Linux PATH tweaks (linuxbrew if present) |
| `install.sh` | Idempotent bootstrap: select OS pkg, stow, post-install |
| `uninstall.sh` | `stow -D` full reversal |
| `Brewfile` | macOS package manifest (data, not stowed) |
| `packages/apt.txt` | Debian/Ubuntu package manifest (data) |
| `packages/dnf.txt` | Fedora package manifest (data) |
| `.gitignore` | Normal denylist (replaces `*`+allowlist) |
| `README.md` | Usage: bootstrap a new machine, daily workflow |

---

## Phase A — Repo restructuring (touches only `~/dotfiles`)

### Task 1: Create package skeleton

**Files:** Create dirs `base/`, `os-darwin/.config/shell/os/darwin/`, `os-linux/.config/shell/os/linux/`, `packages/`.

- [ ] **Step 1: Create directories**

```bash
cd ~/dotfiles
mkdir -p base os-darwin/.config/shell/os/darwin os-linux/.config/shell/os/linux packages
```

- [ ] **Step 2: Verify**

Run: `ls -d base os-darwin os-linux packages`
Expected: all four print.

### Task 2: Move shared files into `base/` (preserve history)

**Files:** `git mv` all tracked shared files from repo root into `base/`.

- [ ] **Step 1: Move shell + dotfiles into base**

```bash
cd ~/dotfiles
# top-level shell rc files
git mv .zshrc .zprofile .profile .bashrc .bash_profile base/
# .config subtrees (shared)
mkdir -p base/.config
git mv .config/shell base/.config/shell
git mv .config/git   base/.config/git
git mv .config/tmux  base/.config/tmux
git mv .config/zsh   base/.config/zsh
git mv .config/nnn   base/.config/nnn      # contains a blob removed in Task 4
# zsh functions dir
git mv .zfunc base/.zfunc
```

- [ ] **Step 2: Verify nothing shared left at root**

Run: `git ls-files | grep -vE '^(base/|os-|packages/|docs/|install|uninstall|Brewfile|README|\.gitignore)' || echo CLEAN`
Expected: only `.config/gh/*`, `.config/1Password/*`, `.config/nnn/*.tar.gz`, `Brewfile`, `install` remain (handled in Tasks 3–7).

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "refactor(dotfiles): move shared config into base stow package"
```

### Task 3: Build `os-darwin` Homebrew module + OS-aware `.profile`

**Files:**
- Create: `os-darwin/.config/shell/os/darwin/homebrew`
- Create: `os-linux/.config/shell/os/linux/path`
- Modify: `base/.profile`
- Remove tracking of dead `base/.config/shell/homebrew_config`

- [ ] **Step 1: Create the darwin homebrew module**

```bash
cat > os-darwin/.config/shell/os/darwin/homebrew <<'EOF'
#!/usr/bin/env sh
# Set PATH, MANPATH, etc., for Homebrew (Apple Silicon prefix).
eval "$(/opt/homebrew/bin/brew shellenv)"
EOF
```

- [ ] **Step 2: Create the linux path module**

```bash
cat > os-linux/.config/shell/os/linux/path <<'EOF'
#!/usr/bin/env sh
# Linuxbrew, if installed.
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && \
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF
```

- [ ] **Step 3: Replace `base/.profile` with the OS-aware version**

```bash
cat > base/.profile <<'EOF'
#!/usr/bin/env bash
SHELL_CONFIG="$HOME/.config/shell"
source "$SHELL_CONFIG/env_variables"
source "$SHELL_CONFIG/aliases"
source "$SHELL_CONFIG/nvm_config"
source "$SHELL_CONFIG/nnn_config"
source "$SHELL_CONFIG/functions"
source "$SHELL_CONFIG/shell_behavior"
source "$SHELL_CONFIG/go"

# OS-specific modules (darwin / linux), provided by the os-* stow package.
OS="$(uname | tr '[:upper:]' '[:lower:]')"
if [ -d "$SHELL_CONFIG/os/$OS" ]; then
  for f in "$SHELL_CONFIG/os/$OS"/*; do
    [ -r "$f" ] && source "$f"
  done
fi
EOF
```

- [ ] **Step 4: Remove the dead `homebrew_config` (superseded by os-darwin/homebrew)**

```bash
git rm base/.config/shell/homebrew_config
```

- [ ] **Step 5: Verify `.profile` syntax loads**

Run: `bash -n base/.profile && echo OK`
Expected: `OK` (no syntax error).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(dotfiles): OS-aware profile sourcing + os-darwin/os-linux packages"
```

### Task 4: Remove tracked junk

**Files:** delete `base/.config/nnn/plugins-*.tar.gz`, any wireshark files, lock files.

- [ ] **Step 1: Remove junk**

```bash
cd ~/dotfiles
git rm -r --ignore-unmatch base/.config/nnn/plugins-*.tar.gz
git rm -r --ignore-unmatch base/.config/wireshark .config/wireshark
git rm --ignore-unmatch 'base/.config/git/.~lock.config#' '.config/git/.~lock.config#'
```

- [ ] **Step 2: Verify no blobs/junk remain tracked**

Run: `git ls-files | grep -E 'wireshark|\.tar\.gz|~lock' || echo CLEAN`
Expected: `CLEAN`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "chore(dotfiles): drop tracked junk (wireshark, nnn blob, lock files)"
```

### Task 5: Stop tracking gh account/machine state

**Files:** untrack `.config/gh/hosts.yml`, `.config/gh/config.yml` (kept on disk in `$HOME`, just not in repo).

- [ ] **Step 1: Untrack gh state**

```bash
cd ~/dotfiles
git rm --cached --ignore-unmatch .config/gh/hosts.yml .config/gh/config.yml
git rm -r --ignore-unmatch .config/gh   # remove now-empty tracked dir if present
```

- [ ] **Step 2: Verify**

Run: `git ls-files | grep 'config/gh' || echo CLEAN`
Expected: `CLEAN`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "chore(dotfiles): stop tracking gh account/machine state"
```

### Task 6: New `.gitignore` (denylist)

**Files:** Replace `.gitignore`.

- [ ] **Step 1: Write the denylist**

```bash
cd ~/dotfiles
cat > .gitignore <<'EOF'
# OS / editor cruft
.DS_Store
*~
.*.sw[a-p]
.~lock.*#

# Machine/account state — never track
.config/gh/hosts.yml
.config/gh/config.yml

# Binary blobs (manage via package manifests, not git)
*.tar.gz

# Local editor project dirs
/.idea/
EOF
```

- [ ] **Step 2: Verify docs/ is now trackable**

Run: `git check-ignore docs/superpowers/plans/2026-06-18-dotfiles-stow-migration.md || echo "NOT IGNORED"`
Expected: `NOT IGNORED`.

- [ ] **Step 3: Commit (and add the spec/plan that the old gitignore had blocked)**

```bash
git add .gitignore docs/
git commit -m "chore(dotfiles): replace allowlist gitignore with denylist"
```

### Task 7: Salvage cross-branch assets + author install/uninstall/README/manifests

**Files:**
- Create: `install.sh`, `uninstall.sh`, `README.md`, `packages/apt.txt`, `packages/dnf.txt`
- Move: root `Brewfile` stays at root (data); salvage `.cursor/` and apt list from other branches.

- [ ] **Step 1: Salvage `.cursor/` (from devcontainer) into base and apt list (from ubuntu_2204)**

```bash
cd ~/dotfiles
git checkout origin/devcontainer -- .cursor && mkdir -p base && git mv .cursor base/.cursor
git checkout origin/ubuntu_2204 -- apt_package_list.txt && git mv apt_package_list.txt packages/apt.txt
```

- [ ] **Step 2: Seed `packages/dnf.txt` (no Fedora list existed; core toolset)**

```bash
cat > packages/dnf.txt <<'EOF'
git
stow
zsh
tmux
fzf
ripgrep
fd-find
bat
EOF
```

- [ ] **Step 3: Write `install.sh`**

```bash
cat > install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}"
INSTALL_PACKAGES=0

usage() { echo "Usage: $0 [--packages] [--target DIR]"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --packages) INSTALL_PACKAGES=1 ;;
    --target) shift; TARGET="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

case "$(uname)" in
  Darwin) OS_PKG="os-darwin" ;;
  Linux)  OS_PKG="os-linux" ;;
  *) echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
esac
echo "OS package: $OS_PKG"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found (brew/apt/dnf install stow)." >&2; exit 1
fi

if [ "$INSTALL_PACKAGES" -eq 1 ]; then
  case "$(uname)" in
    Darwin) command -v brew >/dev/null 2>&1 && brew bundle --file="$DOTFILES_DIR/Brewfile" ;;
    Linux)
      if command -v apt >/dev/null 2>&1; then
        sudo apt-get update && xargs -a "$DOTFILES_DIR/packages/apt.txt" sudo apt-get install -y
      elif command -v dnf >/dev/null 2>&1; then
        xargs -a "$DOTFILES_DIR/packages/dnf.txt" sudo dnf install -y
      fi ;;
  esac
fi

cd "$DOTFILES_DIR"
stow --restow --no-folding --target="$TARGET" base "$OS_PKG"
echo "Symlinks created for base + $OS_PKG -> $TARGET"

[ -d "$HOME/.oh-my-zsh" ] || git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
[ -d "$HOME/.tmux/plugins/tpm" ] || git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

if [ "$TARGET" = "$HOME" ] && [ "$(basename "${SHELL:-}")" != "zsh" ] && command -v zsh >/dev/null 2>&1; then
  echo "Changing default shell to zsh..."
  chsh -s "$(command -v zsh)" || echo "chsh failed; change shell manually." >&2
fi

echo "Done."
EOF
chmod +x install.sh
```

- [ ] **Step 4: Write `uninstall.sh`**

```bash
cat > uninstall.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HOME}"
case "$(uname)" in
  Darwin) OS_PKG="os-darwin" ;;
  Linux)  OS_PKG="os-linux" ;;
  *) echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
esac
cd "$DOTFILES_DIR"
stow -D --no-folding --target="$TARGET" base "$OS_PKG"
echo "Removed symlinks for base + $OS_PKG from $TARGET"
EOF
chmod +x uninstall.sh
```

- [ ] **Step 5: Write `README.md`**

```bash
cat > README.md <<'EOF'
# dotfiles

GNU Stow-managed dotfiles. The repo is a self-contained directory; `install.sh`
symlinks the `base` package plus the OS-specific package (`os-darwin` / `os-linux`)
into `$HOME`.

## Bootstrap a new machine
```sh
git clone https://github.com/anthnyalxndr/dotfiles.git ~/dotfiles
cd ~/dotfiles
# install GNU Stow first: brew install stow | sudo apt install stow | sudo dnf install stow
./install.sh --packages   # omit --packages to skip brew/apt/dnf installs
```

## Daily workflow
- Edit files directly in `~/dotfiles/base/...` (they are symlinked into `$HOME`).
- After adding new files to a package: `stow -R --no-folding base os-darwin`.
- Remove all symlinks: `./uninstall.sh`.

## Layout
- `base/` — shared config (stowed everywhere)
- `os-darwin/`, `os-linux/` — OS-specific modules sourced via `.profile`
- `Brewfile`, `packages/apt.txt`, `packages/dnf.txt` — package manifests (data)
EOF
```

- [ ] **Step 6: Lint scripts**

Run: `bash -n install.sh && bash -n uninstall.sh && echo OK`
Expected: `OK`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(dotfiles): add install/uninstall scripts, manifests, README; salvage cursor+apt"
```

---

## Phase B — Sandbox verification (touches only a temp dir)

### Task 8: Dry-run + sandbox stow into a temp `$HOME`

- [ ] **Step 1: Dry run against live HOME (no changes made)**

Run: `cd ~/dotfiles && stow -n -v --no-folding --target="$HOME" base os-darwin 2>&1 | tail -30`
Expected: prints planned `LINK:` lines; any `CONFLICT` lines are existing real copies in `$HOME` — note them for Phase C's backup step. No files are modified (dry run).

- [ ] **Step 2: Stow into a clean sandbox dir**

```bash
SBX="$(mktemp -d)"; echo "sandbox=$SBX"
cd ~/dotfiles && stow --no-folding --target="$SBX" base os-darwin
```

- [ ] **Step 3: Verify symlink tree + sourcing loads**

```bash
readlink "$SBX/.zshrc"; readlink "$SBX/.config/shell/aliases"
[ -e "$SBX/.config/shell/os/darwin/homebrew" ] && echo "os module linked"
HOME="$SBX" bash -ic 'source "$SBX/.profile"; echo PROFILE_OK' 2>&1 | tail -5
```
Expected: readlinks point into `~/dotfiles/base` and `~/dotfiles/os-darwin`; `PROFILE_OK` prints (brew shellenv may warn if brew absent in sandbox — acceptable).

- [ ] **Step 4: Tear down sandbox**

```bash
cd ~/dotfiles && stow -D --no-folding --target="$SBX" base os-darwin && rm -rf "$SBX" && echo "sandbox clean"
```

---

## Phase C — Apply to live `$HOME` (CHECKPOINT: confirm before running)

### Task 9: Back up conflicting copies, then stow into `$HOME`

- [ ] **Step 1: Back up every file `$HOME` has that a package would link**

```bash
BACKUP="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BACKUP"; echo "backup=$BACKUP"
cd ~/dotfiles
# For each path stow would manage, move any existing real (non-symlink) file aside.
stow -n -v --no-folding --target="$HOME" base os-darwin 2>&1 \
  | sed -n 's/^.*existing target is neither a link nor a directory: //p' \
  | while read -r rel; do
      if [ -e "$HOME/$rel" ] && [ ! -L "$HOME/$rel" ]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"; mv "$HOME/$rel" "$BACKUP/$rel"; echo "backed up $rel"
      fi
    done
```

- [ ] **Step 2: Stow into live HOME**

Run: `cd ~/dotfiles && ./install.sh`
Expected: "Symlinks created for base + os-darwin -> /Users/ata"; no CONFLICT errors (backups cleared them).

- [ ] **Step 3: Verify links + interactive shell loads clean**

```bash
readlink "$HOME/.zshrc"; readlink "$HOME/.config/shell/aliases"
zsh -ic 'echo ZSH_OK' 2>&1 | tail -10
```
Expected: links resolve into `~/dotfiles`; `ZSH_OK` prints with no sourcing errors.

- [ ] **Step 4: Verify idempotency + reversibility**

```bash
cd ~/dotfiles && ./uninstall.sh && readlink "$HOME/.zshrc" 2>&1 || echo "unlinked OK"
./install.sh && readlink "$HOME/.zshrc"   # re-link
```
Expected: uninstall removes links; reinstall recreates them; no errors.

---

## Phase D — Git history finalization (CHECKPOINT: confirm before running)

### Task 10: Archive old branches, promote `main`, clean up remote

- [ ] **Step 1: Tag + push archive backups of all five branches**

```bash
cd ~/dotfiles
for b in darwin fedora ubuntu_2204 ubuntu_2401 devcontainer; do
  git tag "archive/$b" "origin/$b"
done
git push origin --tags
```

- [ ] **Step 2: Create `main` from the migration branch**

```bash
git branch main feat/stow-migration
git push -u origin main
```

- [ ] **Step 3: Set GitHub default branch to `main`**

```bash
gh repo edit anthnyalxndr/dotfiles --default-branch main
```

- [ ] **Step 4: Delete the five old remote branches (safe — archived as tags)**

```bash
for b in darwin fedora ubuntu_2204 ubuntu_2401 devcontainer; do
  git push origin --delete "$b"
done
git remote prune origin
```

- [ ] **Step 5: Verify final remote state**

```bash
gh api repos/anthnyalxndr/dotfiles --jq .default_branch
git ls-remote --heads origin
git ls-remote --tags origin | grep archive/
```
Expected: default branch `main`; only `main` under heads; five `archive/*` tags present.

---

## Self-Review

**Spec coverage:**
- Stow model + leaf-dir / no nesting → Tasks 1–3, 8 (`--no-folding`). ✔
- base + os-darwin + os-linux → Tasks 1–3, 7. ✔
- OS-aware sourcing (no branches/templating) → Task 3. ✔
- install.sh idempotent + uninstall.sh → Task 7, verified Task 9 step 4. ✔
- Cleanup junk + untrack gh + new gitignore → Tasks 4–6. ✔
- Preserve darwin as main, archive + delete branches → Task 10. ✔
- Verification (dry-run, readlink, zsh load) → Tasks 8–9. ✔
- Salvage apt list + .cursor → Task 7. ✔

**Placeholder scan:** No TBD/TODO; every file's full content is inline; `dnf.txt` is seeded (not a placeholder) since no Fedora list existed upstream.

**Consistency:** Package names `base`/`os-darwin`/`os-linux`, `--no-folding`, and `SHELL_CONFIG/os/$OS` are used identically across install.sh, uninstall.sh, `.profile`, and verification tasks.

**Known stale config (flagged, out of scope unless requested):** `base/.zprofile` pins a Python 2.7 path; `base/.bash_profile` has a broken `./usr/local/...` line; `base/.bashrc:11` hardcodes `brew shellenv` (now also provided by os-darwin). These migrate as-is; clean up in a follow-up if desired.
