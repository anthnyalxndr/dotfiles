function save_directory_stack {
  # Append the current dir stack to the recent list, then dedup in place.
  # (Writes to ~/.zdirs only — never into ~/.dotfiles, which is the bare git dir.)
  dirs -p | sed -e "s|^~|$HOME|" >> ~/.zdirs
  temp=$(tail -r ~/.zdirs | awk '!x[$0]++' | tail -r)
  echo $temp >~/.zdirs
}
trap save_directory_stack EXIT
