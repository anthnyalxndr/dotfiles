#!/usr/bin/env bash
# macOS one-time provisioning: default-app associations and other `defaults`
# tweaks. Idempotent and re-runnable. Invoked by bootstrap.sh AFTER Homebrew and
# `brew bundle` have populated the machine, but also safe to run standalone:
#   ~/.config/dotfiles/macos-defaults.sh
#
# This script does NOT install anything. It checks that the software it needs is
# present and prints an actionable error if not (see preflight below).
set -euo pipefail

[ "$(uname)" = "Darwin" ] || { echo "macos-defaults: not macOS, skipping."; exit 0; }

# --- Preflight: verify required software, error usefully if missing ----------
# duti drives Launch Services; it ships in the Brewfile. Cursor is the target
# app — we resolve its bundle id via Launch Services rather than hardcoding, so
# a ToDesktop id change doesn't silently break things.
missing=()
command -v duti >/dev/null 2>&1 || missing+=("duti — install with 'brew install duti' (it's in the Brewfile)")

CURSOR_BUNDLE="$(osascript -e 'id of app "Cursor"' 2>/dev/null || true)"
[ -n "$CURSOR_BUNDLE" ] || missing+=("Cursor — install it from https://cursor.com/download")

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "macos-defaults: required software not installed:"
    for m in "${missing[@]}"; do echo "  - $m"; done
    echo "Skipping default-app associations. Re-run this script once the above are installed:"
    echo "  ~/.config/dotfiles/macos-defaults.sh"
  } >&2
  exit 1
fi

# --- Default code editor: point code/config/markup file types at Cursor ------
# Concrete extensions (no leading dot). Broad but code-focused.
# NOTE: .html/.htm are intentionally omitted — Chrome holds a strong claim on
# public.html and Launch Services rejects the override (error -54). To route
# HTML to Cursor anyway, use Finder → Get Info → Open with → Change All.
EXTS=(
  js mjs cjs jsx ts tsx mts cts vue svelte astro
  py pyi pyw pyx
  rb erb rake gemspec pl pm php lua
  go rs zig nim v d cr
  c h cc cpp cxx hpp hh hxx m mm
  java kt kts scala sc groovy gradle clj cljs cljc edn
  swift cs fs fsx
  hs elm ex exs erl ml mli jl dart r
  sh bash zsh fish ksh ps1 psm1 bat cmd
  proto cmake mk tf tfvars hcl sol wat asm s
  json jsonc json5 yaml yml toml ini cfg conf
  sql graphql gql prisma
  css scss sass less
  md markdown mdx rst tex adoc
  xml editorconfig gitignore gitattributes dockerignore npmrc babelrc eslintrc prettierrc
)

# Shared UTIs — backstop so extension-less / UTI-keyed files (Makefile,
# Dockerfile, generic "source code") also route to Cursor.
UTIS=(
  public.source-code public.shell-script public.script public.plain-text
  public.json public.yaml public.xml
  public.python-script public.ruby-script public.perl-script public.php-script
  public.c-source public.c-plus-plus-source public.c-header
  public.objective-c-source public.swift-source
  net.daringfireball.markdown com.netscape.javascript-source public.css
)

set_default_apps() {
  local ok=0 fail=0 t
  for t in "${EXTS[@]}" "${UTIS[@]}"; do
    if duti -s "$CURSOR_BUNDLE" "$t" all 2>/dev/null; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1)); echo "  ! could not set: $t" >&2
    fi
  done
  echo "Default apps -> Cursor ($CURSOR_BUNDLE): applied $ok, skipped $fail."
}

echo "Applying default-app associations..."
set_default_apps

# --- Future macOS `defaults write ...` tweaks go below -----------------------
