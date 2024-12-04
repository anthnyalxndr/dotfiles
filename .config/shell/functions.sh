#!/usr/bin/env sh

# Character utility functions

# ord returns the character code associated with a character
ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

# chr returns the character associated with a character code
chr() {
  [ "$1" -lt 256 ] || return 1
  octal=$(printf '%o' "$1")
  escaped_octal=\\$octal
  printf "%s" "$escaped_octal"
}