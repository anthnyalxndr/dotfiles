function save_directory_stack {
  dirs -p | sed -e "s|^~|$HOME|" >> ~/.dotfiles/shell/.recent_directories
  temp=$(tail -r ~/.zdirs | awk '!x[$0]++' | tail -r)
  echo $temp >~/.zdirs
}
trap save_directory_stack EXIT
