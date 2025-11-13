#!/usr/bin/env bash

# --- Globals ---
max_items=0   # Will be set by get_terminal_size
list=()       # The array of files in the current dir
cur_list=()   # A backup of the list
list_total=0  # The index of the last item in the list

scroll_index=0        # Index in the main 'list' array (0 to list_total)
window_start_index=0  # 'list' index currently at the top of the screen
cursor_y=0            # Visual cursor row on screen (0 to max_items-1)
previous_index=0      # To remember the previous dir index


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

# search_mode() {

# }

open() {
  local selected_item=$1

  # if the selected item is a directory
  if [[ -d $selected_item ]]; then

      cd "$selected_item"
      read_current_directory # Re-read data from disk
      scroll_index=0         # Reset cursor
      window_start_index=0
      cursor_y=0
      draw_screen            # Re-draw

  # if the seletced is a file
  elif [[ -f $selected_item ]]; then

      # getting only the name of the file
      local filename=${selected_item##*/}

      case "$selected_item" in
        # text files
        *.txt|*.md|*.rtf|*.log|*.cfg|*.conf|*.ini|*.json|*.yaml|*.yml|*.toml|\
        *.csv|*.tsv|*.xml|*.html|*.htm|*.css|*.scss|*.less|*.js|*.mjs|*.ts|*.jsx|*.tsx|\
        *.c|*.cpp|*.cc|*.cxx|*.h|*.hpp|*.hxx|*.ino|\
        *.java|*.kt|*.kts|*.groovy|*.gradle|\
        *.py|*.pyw|*.ipynb|\
        *.sh|*.bash|*.zsh|*.fish|*.ps1|*.bat|*.cmd|\
        *.php|*.rb|*.pl|*.pm|*.lua|*.tcl|*.r|*.jl|*.go|*.rs|*.swift|\
        *.sql|*.db|*.sqlite|*.sqlite3|\
        *.make|Makefile|makefile|CMakeLists.txt|\
        *.ini|*.env|.env|.env.*|\
        *.tex|*.bib|*.sty|\
        *.csv|*.tsv|*.dat|*.lst|\
        *.lock|*.bak|*.old|*.tmp|*.cache|\
        *.dockerfile|Dockerfile|docker-compose.yml|docker-compose.yaml|\
        *.service|*.target|*.mount|*.socket|*.timer|\
        *.gitignore|*.gitattributes|*.gitconfig|\
        *.LICENSE|LICENSE|LICENSE.*|COPYING|README|README.*|\
        *.mdx|*.rst|*.adoc|*.org|\
        *.y|*.yy|*.l|*.lex|*.bison|\
        *.hpp.in|*.h.in|*.c.in|*.cpp.in|\
        *.vim|*.vimrc|.vimrc|init.vim|*.nvim|*.lua|\
        *.jsonc|*.avsc|*.proto|*.thrift|\
        *.toml|pyproject.toml|Cargo.toml|package.json|tsconfig.json|composer.json|\
        *.asm|*.s|*.S|\
        *.dart|*.ex|*.exs|*.erl|*.hrl|*.clj|*.cljs|*.scala|*.ml|*.mli|*.hs|*.lhs|\
        *.vb|*.cs|*.fs|*.fsx|*.v|*.sv|*.vhd|*.vhdl|\
        *.gradle|*.properties|*.prefs|\
        *.ninja|*.build|*.bazel|*.bzl|WORKSPACE|BUILD|BUILD.bazel|\
        *.cfg|*.conf|*.ini|*.rc|*.prefs|\
        *.ipynb|*.nb|\
        *.toml|*.lock|*.yaml|*.yml|*.conf|\
        *.desktop|*.spec|*.rc|*.plist|*.json5)

                if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
                    zellij action new-pane --name "$filename" --close-on-exit -- \
                            $SHELL -c 'nvim "$1"; exit' "pane-shell" "$selected_item"
                else
                    reset_terminal
                    nvim "$selected_item"
                    setup_terminal # Re-enter TUI mode
                    draw_screen    # Re-draw
                fi
                ;;

        # media files ( uses chafa )
        *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.mp4)
              if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then

                  zellij action new-pane --name "$filename" --close-on-exit -- \
                      $SHELL -c "chafa '$selected_item'; read -n 1 -s -r -p 'Press any key to close...'"
              else
                  # Fallback: open in current terminal
                  reset_terminal
                  chafa "$selected_item"
                  read -n 1 -s -r -p 'Press any key to close...'
                  setup_terminal
                  draw_screen
              fi
              ;;

        *)
        if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
                zellij action new-pane --name "$filename" --close-on-exit -- \
                        $SHELL -c 'nvim "$1"; exit' "pane-shell" "$selected_item"
            else
                reset_terminal
                nvim "$selected_item"
                setup_terminal # Re-enter TUI mode
                draw_screen    # Re-draw
            fi
            ;;

      esac

  fi

}

get_terminal_size() {
  read -r LINES COLUMNS < <(stty size)
  max_items=$((LINES - 3)) # Reserve 3 lines for status/header
}

read_current_directory() {
  local dirs=() files=() item_index=0 path

  path=$PWD
  [[ $path == / ]] && path=

  for item in "$path"/*; do
      if [[ -d $item ]]; then
          dirs+=("$item")
          # We'll use this later to remember cursor position
          [[ $item == "$OLDPWD" ]] && ((previous_index=item_index))
          ((item_index++))
      else
          files+=("$item")
      fi
  done

  list=("${dirs[@]}" "${files[@]}")
  [[ -z ${list[0]} ]] && list[0]="empty"
  ((list_total=${#list[@]} - 1))

}

draw_status_line() {

    printf "\e[${LINES};0H" # Move to bottom row
    printf "\e[K"           # Clear the Line
    # Background: \e[48;5;214m
    # Foreground (black): \e[30m
    # Reset: \e[0m
    printf "\e[48;5;214m\e[30m \e[7mSelected: ${list[scroll_index]##*/} ($((scroll_index+1))/$((list_total+1)))\e[m \e[0m"

    # printf "\e[48;5;214m\e[30m Selected: ${list[scroll_index]##*/} ($scroll_index/$list_total) \e[0m"
}


draw_screen() {
    # Clear the screen (the cause of our flicker)
    printf '\e[H\e[2J'

    # --- Draw the File List (The Window) ---
    for(( i=0; i<max_items; i++)); do
        # Get the real data index from our main 'list'
        local data_index=$(( window_start_index + i ))

        # Stop if we're past the end of the real list
        (( data_index > list_total )) && break

        local item_path="${list[data_index]}"
        [[ -z "$item_path" ]] && break # Stop on empty item

        local item_name="${item_path##*/}"
        [[ -d "$item_path" ]] && item_name+="/"

        # --- The New Highlight Logic ---
        # Check if the visual row 'i' matches our cursor's visual row 'cursor_y'
        if (( i == cursor_y )); then
            printf '\e[48;5;214m\e[30m%s\e[0m\n' "$item_name"
        else
            printf '%s\n' "$item_name"
        fi
    done

   draw_status_line
}


function main {
  # Trap resize events: get new size and redraw
  # SIGWINCH is the signal for terminal resize
  trap 'get_terminal_size; draw_screen' SIGWINCH

  # Run all setup
  setup_terminal
  get_terminal_size


  # 1. Load data ONCE at the start
  read_current_directory

  # 2. Draw screen ONCE at the start
  draw_screen

  for ((;;)); do
      # 3. Wait for a key
      read -s -n 1 k

      if [[ $k == $'\e' ]]; then
        read -rsn1 k2
        read -rsn1 k3
        k="$k$k2$k3"
      fi

      # 4. Handle the key
      case "$k" in
          q) # Quit
              break ;;

          j|$'\e[B') # SCROLL DOWN
              if (( scroll_index < list_total )); then
                  ((scroll_index++)) # Move data cursor down

                  if (( cursor_y < (max_items - 1) )); then
                      # --- Case 1: Just move visual cursor ---
                      ((cursor_y++))
                  else
                      # --- Case 2: At bottom, scroll window ---
                      ((window_start_index++))
                  fi
                  draw_screen
              fi
              ;;

          k|$'\e[A') # SCROLL UP
              if (( scroll_index > 0 )); then
                  ((scroll_index--)) # Move data cursor up

                  if (( cursor_y > 0 )); then
                      # --- Case 1: Just move visual cursor ---
                      ((cursor_y--))
                  else
                      # --- Case 2: At top, scroll window ---
                      ((window_start_index--))
                  fi
                  draw_screen
              fi
              ;;

          l|$'\e[C') # OPEN (l = right)
              open "${list[scroll_index]}"
              ;;

          h|$'\e[D') # GO BACK (h = left)
              cd ..
              read_current_directory # Re-read data
              # 1. Set our target data position
              scroll_index=$previous_index

              # 2. Safety check
              # If the index is out of bounds (e.g., file deleted), reset to 0
              (( scroll_index > list_total )) && scroll_index=0

              # 3. --- Apply "Smooth Scroll" Centering Logic ---

              # Calculate the "middle" of the screen
              local half_window=$(( max_items / 2 ))

              if (( scroll_index < half_window )); then
                  # --- CASE 1: Near the TOP ---
                  # The item is in the top-half of the first page.
                  # Just set the window to the top.
                  window_start_index=0
                  cursor_y=$scroll_index

              elif (( (list_total - scroll_index) < half_window )); then
                  # --- CASE 2: Near the BOTTOM ---
                  # The item is in the bottom-half of the last page.
                  # "Pin" the window to the bottom.
                  window_start_index=$(( list_total - max_items + 1 ))

                  # Safety check: don't let window_start go below 0
                  # (This happens if the total list is smaller than max_items)
                  (( window_start_index < 0 )) && window_start_index=0

                  # The cursor is the offset from the new window start
                  cursor_y=$(( scroll_index - window_start_index ))

              else
                  # --- CASE 3: In the MIDDLE ---
                  # This is the "true" smooth scroll.
                  # Center the window around the scroll_index.
                  window_start_index=$(( scroll_index - half_window ))
                  cursor_y=$half_window
              fi
              draw_screen            # Re-draw
              ;;

      esac
  done

  # 5. Cleanup
  reset_terminal
}

main "$@"