#!/bin/bash

key() {
  local key_pressed=$1
  echo "$key_pressed pressed"
}

get_terminal_size() {

  # LINES STORES THE MAX NUMBER ITEMS THAT CAN BE DISPLAYED
  read -r LINES COLUMNS < <(stty size)

  # Max list items that fit in the scroll area.
  max_items=$((LINES - 3))

}

setup_terminal() {
    # Setup the terminal for the TUI.
    # '\e[?1049h': Use alternative screen buffer.
    # '\e[?7l':    Disable line wrapping.
    # '\e[?25l':   Hide the cursor.
    # '\e[2J':     Clear the screen.
    # '\e[1;Nr':   Limit scrolling to scrolling area.
    #              Also sets cursor to (0,0).
    printf '\e[?1049h\e[?7l\e[?25l\e[2J\e[1;%sr' "$max_items"

    # Hide echoing of user input
    stty -echo
}

reset_terminal() {
    # Reset the terminal to a useable state (undo all changes).
    # '\e[?7h':   Re-enable line wrapping.
    # '\e[?25h':  Unhide the cursor.
    # '\e[2J':    Clear the terminal.
    # '\e[;r':    Set the scroll region to its default value.
    #             Also sets cursor to (0,0).
    # '\e[?1049l: Restore main screen buffer.
    printf '\e[?7h\e[?25h\e[2J\e[;r\e[?1049l'

    # Show user input.
    stty echo
}

clear_screen() {
    # Only clear the scrolling window (dir item list).
    # '\e[%sH':    Move cursor to bottom of scroll area.
    # '\e[9999C':  Move cursor to right edge of the terminal.
    # '\e[1J':     Clear screen to top left corner (from cursor up).
    # '\e[2J':     Clear screen fully (if using tmux) (fixes clear issues).
    # '\e[1;%sr':  Clearing the screen resets the scroll region(?). Re-set it.
    #              Also sets cursor to (0,0).
    printf '\e[%sH\e[9999C\e[1J%b\e[1;%sr' "$((LINES-2))" "${TMUX:+\e[2J}" "$max_items"
}

print_current_directory() {
  
}

read_current_directory() {

}

main() {
  # the core logic comes here

  # so that the app auto-updates LINES and COLUMNS on terminal resize events.
  trap get_terminal_size SIGWINCH

  setup_terminal


  for ((;;)); do
    read -s -n 1 k

    local i=0

    get_terminal_size

    # Move cursor to top-left and clear everything.
    printf '\e[H\e[2J'

    for (( i=0; i<max_items; i++ )); do
      printf '%d\n' "$((i+1))"
    done

    [[ $k == q ]] && break

    key "$k"

    pwd=$(pwd)

    echo "Lets say $pwd comes here"

  done

  reset_terminal

}

main "$@"