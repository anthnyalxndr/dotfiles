# Dotfiles Bare-Repo Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Convert the copy/rsync, branch-per-OS dotfiles repo into a bare git repo (`~/.dotfiles` git dir, `$HOME` work tree) with a single `main` branch and branchless OS-conditional sourcing.

**Architecture:** Files are tracked at home-relative paths and live as real files in `$HOME` (no symlinks → no atomic-rename clobber). A `config` alias drives git; `status.showUntrackedFiles=no` hides the home dir's untracked files and nested repos. The `darwin` branch becomes `main` with history preserved.

**Tech Stack:** git (bare-repo trick), bash.

**Working branch:** `feat/bare-repo` (created from `origin/darwin`).

**Safety model:** Phases A–B touch only `~/dotfiles` (scratch standard clone) and a temp dir — zero impact on the live `$HOME` or remote. Phase C creates `~/.dotfiles` and checks out into the live `$HOME` (CHECKPOINT). Phase D mutates the GitHub remote (CHECKPOINT). Both are made reversible (backup dir / archive tags) before any destructive step.

---

## Phase A — Restructure on the scratch branch (touches only `~/dotfiles`)

> All work happens in the scratch standard clone `~/dotfiles` on `feat/bare-repo`. Paths are
> already home-relative on `darwin`, so this is cleanups + new files, no moves.

### Task 1: Remove tracked junk

- [ ] **Step 1:** `cd ~/dotfiles`
- [ ] **Step 2:**
```bash
git rm -rq --ignore-unmatch .config/wireshark
git rm -q  --ignore-unmatch '.config/nnn/plugins-*.tar.gz' '.config/git/.~lock.config#'
```
- [ ] **Step 3 (verify):** `git ls-files | grep -E 'wireshark|\.tar\.gz|~lock' || echo CLEAN` → `CLEAN`
- [ ] **Step 4:** `git commit -qm "chore(dotfiles): drop tracked junk (wireshark, nnn blob, lock files)"`

### Task 2: Stop tracking gh account/machine state

- [ ] **Step 1:** `git rm -rq --cached --ignore-unmatch .config/gh`
- [ ] **Step 2 (verify):** `git ls-files | grep config/gh || echo CLEAN` → `CLEAN`
- [ ] **Step 3:** `git commit -qm "chore(dotfiles): stop tracking gh account/machine state"`

### Task 3: OS-aware `.profile` + os modules + `config` alias

- [ ] **Step 1: darwin homebrew module**
```bash
mkdir -p .config/shell/os/darwin .config/shell/os/linux
cat > .config/shell/os/darwin/homebrew <<'EOF'
#!/usr/bin/env sh
# Set PATH, MANPATH, etc., for Homebrew (Apple Silicon prefix).
eval "$(/opt/homebrew/bin/brew shellenv)"
EOF
```
- [ ] **Step 2: linux path module**
```bash
cat > .config/shell/os/linux/path <<'EOF'
#!/usr/bin/env sh
# Linuxbrew, if installed.
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && \
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF
```
- [ ] **Step 3: the `config` alias module (sourced by .profile)**
```bash
cat > .config/shell/config_alias <<'EOF'
#!/usr/bin/env sh
# Manage dotfiles via the bare repo without a .git in $HOME.
alias config='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
EOF
```
- [ ] **Step 4: rewrite `.profile` to source shared modules + config_alias + OS dir**
```bash
cat > .profile <<'EOF'
#!/usr/bin/env bash
SHELL_CONFIG="$HOME/.config/shell"
source "$SHELL_CONFIG/env_variables"
source "$SHELL_CONFIG/aliases"
source "$SHELL_CONFIG/config_alias"
source "$SHELL_CONFIG/nvm_config"
source "$SHELL_CONFIG/nnn_config"
source "$SHELL_CONFIG/functions"
source "$SHELL_CONFIG/shell_behavior"
source "$SHELL_CONFIG/go"

# OS-specific modules (darwin / linux).
OS="$(uname | tr '[:upper:]' '[:lower:]')"
if [ -d "$SHELL_CONFIG/os/$OS" ]; then
  for f in "$SHELL_CONFIG/os/$OS"/*; do
    [ -r "$f" ] && source "$f"
  done
fi
EOF
```
- [ ] **Step 5: remove dead `homebrew_config`** (brew shellenv now lives in os/darwin/homebrew)
```bash
git rm -q .config/shell/homebrew_config
```
- [ ] **Step 6 (verify):** `bash -n .profile && echo OK` → `OK`
- [ ] **Step 7:** `git add .config/shell/os .config/shell/config_alias .profile && git commit -qm "feat(dotfiles): OS-aware profile sourcing + config alias + os modules"`

### Task 4: Salvage apt list + cursor; seed dnf

> `.cursor` on disk in `~/dotfiles` may contain stale app-data — add ONLY commands+rules.

- [ ] **Step 1:**
```bash
git checkout origin/ubuntu_2204 -- apt_package_list.txt && mkdir -p packages && git mv apt_package_list.txt packages/apt.txt
git checkout origin/devcontainer -- .cursor/commands .cursor/rules
```
- [ ] **Step 2: seed dnf manifest**
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
- [ ] **Step 3 (verify only intended cursor files):** `git status --porcelain .cursor` lists only `commands/` and `rules/` paths.
- [ ] **Step 4:** `git add .cursor/commands .cursor/rules packages/apt.txt packages/dnf.txt && git commit -qm "feat(dotfiles): salvage apt list + cursor commands/rules; seed dnf"`

### Task 5: New `.gitignore` (denylist incl. bare git dir)

- [ ] **Step 1:**
```bash
cat > .gitignore <<'EOF'
# Bare dotfiles git dir — never track
.dotfiles/

# OS / editor cruft
.DS_Store
*~
.*.sw[a-p]
.~lock.*#

# Machine/account state — never track
.config/gh/hosts.yml
.config/gh/config.yml

# Binary blobs
*.tar.gz
EOF
```
- [ ] **Step 2 (verify docs trackable):** `git check-ignore docs/ >/dev/null && echo IGNORED || echo "NOT IGNORED (good)"`
- [ ] **Step 3:** `git add .gitignore docs/ && git commit -qm "chore(dotfiles): denylist gitignore incl. bare git dir"`

### Task 6: `bootstrap.sh` + `README.md`; remove legacy scripts

- [ ] **Step 1: bootstrap.sh**
```bash
cat > bootstrap.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO="${1:-https://github.com/anthnyalxndr/dotfiles.git}"
GIT_DIR="$HOME/.dotfiles"
config() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

[ -e "$GIT_DIR" ] && { echo "$GIT_DIR already exists; aborting." >&2; exit 1; }
git clone --bare "$REPO" "$GIT_DIR"
config config --local status.showUntrackedFiles no

if ! config checkout 2>/tmp/dotfiles-co.err; then
  BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BACKUP"
  echo "Backing up pre-existing files to $BACKUP"
  awk '/^[[:space:]]+\./{print $1}' /tmp/dotfiles-co.err | while read -r f; do
    mkdir -p "$BACKUP/$(dirname "$f")"; mv "$HOME/$f" "$BACKUP/$f"
  done
  config checkout
fi
echo "Dotfiles checked out. Open a new shell (the 'config' alias loads via ~/.config/shell/config_alias)."
EOF
chmod +x bootstrap.sh
```
- [ ] **Step 2: README.md**
```bash
cat > README.md <<'EOF'
# dotfiles

Managed with a **bare git repo**: git dir `~/.dotfiles`, work tree `$HOME`. Files are real
files in place (no symlinks), so editing a tracked dotfile — by hand or by a tool/agent —
just shows up as a diff in `config status`.

## Bootstrap a new machine
```sh
curl -fsSL https://raw.githubusercontent.com/anthnyalxndr/dotfiles/main/bootstrap.sh | bash
# or: clone this repo and run ./bootstrap.sh
```

## Daily workflow
```sh
config status                 # what changed
config add ~/.zshrc           # stage a specific file (NEVER `config add -A`)
config commit -m "..."        # commit
config push                   # publish
```
`config` is `git --git-dir=$HOME/.dotfiles --work-tree=$HOME` (defined in
`~/.config/shell/config_alias`). `status.showUntrackedFiles` is `no`, so only tracked files
appear — your other repos under `$HOME` stay invisible.

## OS differences
`~/.profile` sources shared `~/.config/shell/*` then `~/.config/shell/os/$(uname)/*`. All OS
files are tracked; only the matching OS is sourced. No branches.

## Layout
- `~/.config/shell/` — shared shell modules + `os/{darwin,linux}/`
- `Brewfile`, `packages/{apt,dnf}.txt` — package manifests
EOF
```
- [ ] **Step 3: remove legacy scripts**
```bash
git rm -q --ignore-unmatch install update_dotfiles
```
- [ ] **Step 4 (lint):** `bash -n bootstrap.sh && echo OK` → `OK`
- [ ] **Step 5:** `git add bootstrap.sh README.md && git commit -qm "feat(dotfiles): add bootstrap.sh + README; remove legacy scripts"`

---

## Phase B — Sandbox verification (temp dir only)

### Task 7: Bare checkout into a throwaway work tree

- [ ] **Step 1: build a bare repo from the scratch branch and check out into a temp HOME**
```bash
cd ~/dotfiles
SBX="$(mktemp -d)"; GBX="$(mktemp -d)/git"; echo "sbx=$SBX gitdir=$GBX"
git clone --bare . "$GBX" >/dev/null 2>&1
cfg() { git --git-dir="$GBX" --work-tree="$SBX" "$@"; }
cfg config --local status.showUntrackedFiles no
cfg checkout feat/bare-repo
```
- [ ] **Step 2 (verify real files, not symlinks):**
```bash
[ -f "$SBX/.zshrc" ] && [ ! -L "$SBX/.zshrc" ] && echo "OK: .zshrc is a regular file"
[ -f "$SBX/.config/shell/os/darwin/homebrew" ] && echo "OK: os module present"
cfg status --porcelain | head    # expect empty (clean tree)
```
- [ ] **Step 3 (verify sourcing + alias):**
```bash
HOME="$SBX" bash -c 'source "$SBX/.config/shell/config_alias"; type config | head -1; echo ALIAS_OK'
```
Expected: `config is aliased to ...`; `ALIAS_OK`.
- [ ] **Step 4 (teardown):** `rm -rf "$SBX" "$(dirname "$GBX")"`

---

## Phase C — Apply to live `$HOME` (CHECKPOINT: confirm before running)

### Task 8: Create the live bare repo and check out into `$HOME`

- [ ] **Step 1: clone bare from the local scratch repo (avoids needing a push first)**
```bash
git clone --bare ~/dotfiles "$HOME/.dotfiles"
config() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
config config --local status.showUntrackedFiles no
config symbolic-ref HEAD refs/heads/feat/bare-repo
```
- [ ] **Step 2: back up conflicting files, then checkout**
```bash
if ! config checkout feat/bare-repo 2>/tmp/dotfiles-co.err; then
  BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BACKUP"
  echo "backup=$BACKUP"
  awk '/^[[:space:]]+\./{print $1}' /tmp/dotfiles-co.err | while read -r f; do
    mkdir -p "$BACKUP/$(dirname "$f")"; mv "$HOME/$f" "$BACKUP/$f"
  done
  config checkout feat/bare-repo
fi
```
- [ ] **Step 3: point origin at GitHub**
```bash
config remote set-url origin https://github.com/anthnyalxndr/dotfiles.git 2>/dev/null \
  || config remote add origin https://github.com/anthnyalxndr/dotfiles.git
```
- [ ] **Step 4 (verify):**
```bash
[ ! -L "$HOME/.zshrc" ] && echo "OK: ~/.zshrc is a real file"
config status --porcelain | head            # expect clean
zsh -ic 'echo ZSH_OK' 2>&1 | tail -5        # loads cleanly; config alias available
```
- [ ] **Step 5 (verify no-clobber property):** append a comment to `~/.zshrc`, run
`config status` → file shows as modified (a diff, not a broken link); revert with
`config checkout -- .zshrc`.

---

## Phase D — Remote finalization (CHECKPOINT: confirm before running)

### Task 9: Archive, promote `main`, clean up remote

- [ ] **Step 1: archive-tag all five old branches and push tags**
```bash
config fetch origin
for b in darwin fedora ubuntu_2204 ubuntu_2401 devcontainer; do
  config tag "archive/$b" "origin/$b"
done
config push origin --tags
```
- [ ] **Step 2: push the migration branch as `main`**
```bash
config branch -m feat/bare-repo main 2>/dev/null || true
config push -u origin main
```
- [ ] **Step 3: set GitHub default branch**
```bash
gh repo edit anthnyalxndr/dotfiles --default-branch main
```
- [ ] **Step 4: delete the five old remote branches**
```bash
for b in darwin fedora ubuntu_2204 ubuntu_2401 devcontainer; do
  config push origin --delete "$b"
done
```
- [ ] **Step 5 (verify):**
```bash
gh api repos/anthnyalxndr/dotfiles --jq .default_branch   # → main
config ls-remote --heads origin                            # → only main
config ls-remote --tags origin | grep archive/             # → five archive tags
```

---

## Self-Review

**Spec coverage:** bare-repo mechanism (Task 8) ✔; showUntrackedFiles+alias (Tasks 3,8) ✔;
branchless OS sourcing (Task 3) ✔; junk/gh/gitignore cleanup (Tasks 1,2,5) ✔; salvage
(Task 4) ✔; bootstrap+README (Task 6) ✔; preserve darwin→main + archive/delete (Task 9) ✔;
sandbox + live + no-clobber verification (Tasks 7,8) ✔.

**Placeholder scan:** none; all file contents inline; `dnf.txt` seeded (no upstream list).

**Consistency:** git dir `~/.dotfiles`, work tree `$HOME`, alias definition, and
`SHELL_CONFIG/os/$OS` are identical across `config_alias`, `.profile`, `bootstrap.sh`,
README, and the verification tasks.

**Known stale config (flagged, out of scope):** `.zprofile` pins a Python 2.7 path;
`.bash_profile` has a broken `./usr/local/...` line; `.bashrc:11` hardcodes `brew shellenv`
(now also in os/darwin/homebrew). Migrate as-is; clean up later if desired.
```
