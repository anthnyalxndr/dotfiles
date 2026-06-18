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

If `$HOME` already has real (non-symlink) copies of these files, move them aside
first (e.g. into a backup dir) so Stow can create the links without conflicts.

## Daily workflow

- Edit files directly in `~/dotfiles/base/...` — they are symlinked into `$HOME`,
  so there is a single source of truth and nothing to sync.
- After adding new files to a package: `stow -R --no-folding base os-darwin`
  (or `os-linux`).
- Remove all symlinks: `./uninstall.sh`.

## Layout

- `base/` — shared config, stowed on every OS.
- `os-darwin/`, `os-linux/` — OS-specific shell modules, sourced via the OS loop in
  `base/.profile` (`~/.config/shell/os/<os>/*`).
- `Brewfile`, `packages/apt.txt`, `packages/dnf.txt` — package manifests (data, not
  stowed).

## How OS differences work

`base/.profile` sources the shared `~/.config/shell/*` modules, then any modules in
`~/.config/shell/os/$(uname)/` provided by the matching `os-*` package. No branches,
no templating — one shared `main` branch.
