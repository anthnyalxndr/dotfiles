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
