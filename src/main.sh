#!/usr/bin/env bash

# all the global vars
max_items=0   # Will be set by get_terminal_size
list=()       # The array of files in the current dir
cur_list=()   # A backup of the list to use in search function
list_total=0  # The index of the last item in the list

scroll_index=0        # Index in the main 'list' array (0 to list_total)
window_start_index=0  # 'list' index currently at the top of the screen
cursor_y=0            # Visual cursor row on screen (0 to max_items-1)
previous_index=0      # To remember the previous dir index

search_term="" # to hold the search keyword
hidden_files_show_mode=0  # var to toggle hidden files ( 0 = off by default )

# the default key_bindings
KEY_QUIT="q"
KEY_DOWN="j"
KEY_UP="k"
KEY_OPEN="l"
KEY_BACK="h"
KEY_SEARCH="/"
KEY_TOGGLE_HIDDEN="."

# loading the config
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bashfm"
CONFIG_FILE="$CONFIG_DIR/config.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

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

search_mode() {

    search_term=""
    local k

    while true; do

        local filtered_list=()

        # using backed up cur_list
        for item in "${cur_list[@]}"; do
            local filename=${item##*/}
            if [[ "$filename" == *"${search_term}"* ]]; then
                filtered_list+=("$item")
            fi
        done

        list=("${filtered_list[@]}")
        [[ -z ${list[0]} ]] && list[0]="empty"
        ((list_total=${#list[@]} - 1))

        scroll_index=0
        window_start_index=0
        cursor_y=0
        draw_screen

        # draw the search over the status bar
        printf "\e[$((LINES-1));0H\e[J" # Go to bottom line & clear everything below ( \e[J )
        printf "\e[48;5;214m\e[30m%s\n" "Enter esc to escape search mode ..."
        printf "\e[48;5;214m\e[30m/%s\e[0m" "$search_term" # ( theme change will be here too )

        read -s -n 1 k

        case "$k" in
            "") # ENTER: confirm search
                break
                ;;
            $'\e') # ESCAPE: cancel search
                # Restore the master list
                list=("${cur_list[@]}")
                ((list_total=${#list[@]} - 1))
                break
                ;;
            $'\177'|$'\b') # BACKSPACE
                # removing the last character
                search_term=${search_term%?}
                ;;
            *) # Any other key
                # add the key to the search term
                search_term+="$k"
                ;;
        esac
    done
}

open() {
  local selected_item=$1

  # if the selected item is a directory
  if [[ -d $selected_item ]]; then

      cd "$selected_item"
      read_current_directory # Re-read data from disk
      scroll_index=0         # Reset cursor
      window_start_index=0
      cursor_y=0
      search_term=""
      draw_screen            # Re-draw

  # if the seletced is a file
  elif [[ -f $selected_item ]]; then

      # getting only the name of the file
      local filename=${selected_item##*/}

      local quoted_path
      printf -v quoted_path "%q" "$selected_item" # Make a shell safe path for audio Logic

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
                elif [[ -n $TMUX ]]; then
                    tmux split-window -h "$SHELL -c 'nvim \"\$1\"; exit' pane-shell "$selected_item""

                else
                    reset_terminal
                    nvim "$selected_item"
                    setup_terminal
                    draw_screen
                fi
                ;;

        # media files ( uses chafa )
        *.png|*.jpg|*.jpeg|*.gif|*.bmp)
              if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then

                  zellij action new-pane --name "$filename" --close-on-exit -- \
                      $SHELL -c "chafa '$selected_item'; read -n 1 -s -r -p 'Press any key to close...'"
             elif [[ -n "$TMUX" ]]; then

                  tmux split-window -h "chafa '$selected_item'; read -n 1 -s -r -p 'Press any key to close...'; exit"
              else
                  setup_terminal # to open a new buffer again
                  chafa "$selected_item"
                  read -n 1 -s -r -p 'Press any key to close...'
                  reset_terminal # closed the new buffer
                  setup_terminal
                  draw_screen
              fi
              ;;

        *.mp3|*.wav|*.flac|*.ogg|*.m4a|*.aac)
            local i
            if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
                zellij action new-pane --name "$filename" --close-on-exit -- \
                    $SHELL -c "

                        printf '\e[H\e[2J';
                        printf 'File: %s\n' '$filename';

                        read -r _ w < <(stty size); ((w -= 4));

                        ffmpeg -hide_banner -loglevel error -i $quoted_path -filter_complex \"showwavespic=s=\${w}x120:colors=fire\" -frames:v 1 -f image2pipe -v quiet - | chafa -f symbols -;

                        printf '\nPlaying... (Ctrl^C to quit)\n'; # temporary

                        ffplay -hide_banner -loglevel error -autoexit -nodisp $quoted_path < /dev/tty; # ffplay blocks user input while running so we give direct access to keyboard for getting q

                        exit;
                    "
            elif [[ -n "$TMUX" ]]; then

                tmux split-window -h "

                    printf '\e[H\e[2J';
                    printf 'File: %s\n' '$filename';
                    printf 'Generating waveform...\n\n';
                    read -r _ w < <(stty size); ((w -= 4));
                    ffmpeg -hide_banner -loglevel error -i $quoted_path -filter_complex \"showwavespic=s=\${w}x120:colors=fire\" -frames:v 1 -f image2pipe -v quiet - | chafa -f symbols -;
                    printf '\nPlaying... (Ctrl^C to quit)\n';
                    ffplay -hide_banner -loglevel error -autoexit -nodisp $quoted_path < /dev/tty;
                    exit;
                "
            else
                setup_terminal

                printf '\e[H\e[2J';
                printf 'File: %s\n' "$filename";

                # Get width inside the new shell
                read -r _ w < <(stty size); ((w -= 4));

                ffmpeg -hide_banner -loglevel error -i "$selected_item" -filter_complex "showwavespic=s="$w"x120:colors=fire" -frames:v 1 -f image2pipe -v quiet - | chafa -f symbols -;

                printf '\nPlaying... (Ctrl^C to quit)\n'; # temporary

                ffplay -hide_banner -loglevel error -autoexit -nodisp "$selected_item" < /dev/tty;

                reset_terminal
                setup_terminal
                draw_screen
            fi
            ;;

        # using ffplay for videos
        *.mp4|*.mkv|*.mov|*.avi|*.webm)
              if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then

                  zellij action new-pane --name "$filename" --close-on-exit -- ffplay -autoexit "$selected_item"

              elif [[ -n "$TMUX" ]]; then
                    # will refine this logic later
                  tmux split-window -h "
                    ffplay -autoexit '$selected_item' < /dev/tty;
                    exit;
                  "

              else
                  setup_terminal
                  ffplay -autoexit "$selected_item"
                  reset_terminal
                  setup_terminal
                  draw_screen
              fi
              ;;

        # will open any other file in neovim
        *)
            if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
                zellij action new-pane --name "$filename" --close-on-exit -- $SHELL -c 'nvim "$1"; exit' "pane-shell" "$selected_item"
            elif [[ -n $TMUX ]]; then
                    tmux split-window -h "$SHELL -c 'nvim \"\$1\"; exit' pane-shell "$selected_item""
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
  max_items=$((LINES - 3)) # reserving 3 lines for status
}

read_current_directory() {

  if (( hidden_files_show_mode == 1 )); then
      shopt -s dotglob # setting dotglob , showing the hidden files in *
  else
      shopt -u dotglob # unsetting dotglob , hiding the hidden files in *
  fi

  local dirs=() files=() item_index=0 path

  path=$PWD
  # removing / if root directory for neatness
  [[ $path == / ]] && path=

  for item in "$path"/*; do
      if [[ -d $item ]]; then
          dirs+=("$item")
          [[ $item == "$OLDPWD" ]] && ((previous_index=item_index))
          ((item_index++))
      else
          files+=("$item")
      fi
  done

  list=("${dirs[@]}" "${files[@]}")
  [[ -z ${list[0]} ]] && list[0]="empty"
  ((list_total=${#list[@]} - 1))

  cur_list=("${list[@]}")

}

draw_status_line() {

    printf "\e[${LINES};0H" # move to bottom row
    printf "\e[K"           # clear the Line
    # background: \e[48;5;214m
    # foreground (black): \e[30m
    # reset: \e[0m
    printf "\e[48;5;214m\e[30m \e[7mSelected: ${list[scroll_index]##*/} ($((scroll_index+1))/$((list_total+1)))\e[m \e[0m"
}


draw_screen() {

    printf '\e[H\e[2J'


    for(( i=0; i<max_items; i++)); do
        # Getting the real data index from our list
        local data_index=$(( window_start_index + i ))

        # Stopping if we are past the end of the real list
        (( data_index > list_total )) && break

        local item_path="${list[data_index]}"
        [[ -z "$item_path" ]] && break # Stop on empty item

        local item_name="${item_path##*/}"
        [[ -d "$item_path" ]] && item_name+="/"

        # Checking if the visual row i matches our cursor's visual row cursor_y
        if (( i == cursor_y )); then
            printf '\e[48;5;214m\e[30m%s\e[0m\n' "$item_name"
        else
            printf '%s\n' "$item_name"
        fi
    done

   draw_status_line
}


function main {
  # trapping resize events: getting new size and redraw
  # SIGWINCH is the signal for terminal resize
  trap 'get_terminal_size; draw_screen' SIGWINCH


 # setting up
  setup_terminal
  get_terminal_size
  read_current_directory
  draw_screen

  for ((;;)); do
      # getting user input ( used timeouts to avoid blocks )
      read -s -n 1 -t 0.1 k

      if [[ $k == $'\e' ]]; then
        read -rsn1 -t 0.01 k2
        read -rsn1 -t 0.01 k3
        k="$k$k2$k3"
      fi



      # handling the key
      if [[ -n "$k" ]]; then
      case "$k" in
          "$KEY_QUIT") # quit
              break ;;

          "$KEY_DOWN"|$'\e[B') # SCROLL DOWN
              if (( scroll_index < list_total )); then
                  ((scroll_index++)) # move data cursor down

                  if (( cursor_y < (max_items - 1) )); then
                      ((cursor_y++))
                  else
                      ((window_start_index++))
                  fi
                  draw_screen
              fi
              ;;

          "$KEY_UP"|$'\e[A') # SCROLL UP
              if (( scroll_index > 0 )); then
                  ((scroll_index--)) # move data cursor up

                  if (( cursor_y > 0 )); then
                      ((cursor_y--))
                  else
                      ((window_start_index--))
                  fi
                  draw_screen
              fi
              ;;

          "$KEY_OPEN"|$'\e[C') # OPEN
              open "${list[scroll_index]}"
              ;;

          "$KEY_BACK"|$'\e[D') # GO BACK
              cd ..
              read_current_directory # Re-read data
              search_term=""

              scroll_index=$previous_index

              # safety check
              # If the index is out of bounds (e.g., file deleted), reset to 0

              (( scroll_index > list_total )) && scroll_index=0

              # Calculate the "middle" of the screen
              local half_window=$(( max_items / 2 ))

              if (( scroll_index < half_window )); then
                  # case1 near the TOP
                  # The item is in the top-half of the first page.
                  # Just set the window to the top.
                  window_start_index=0
                  cursor_y=$scroll_index

              elif (( (list_total - scroll_index) < half_window )); then
                  # case2 near the BOTTOM
                  # The item is in the bottom-half of the last page.
                  # PIN the window to the bottom.
                  window_start_index=$(( list_total - max_items + 1 ))

                  # don't let window_start go below 0
                  # This happens if the total list is smaller than max_items
                  (( window_start_index < 0 )) && window_start_index=0

                  # The cursor is the offset from the new window start
                  cursor_y=$(( scroll_index - window_start_index ))

              else
                  # case3 in the MIDDLE
                  # Center the window around the scroll_index.
                  window_start_index=$(( scroll_index - half_window ))
                  cursor_y=$half_window
              fi
              draw_screen
              ;;

        "$KEY_SEARCH")
              search_mode
              search_term=""
              draw_screen
              ;;

        "$KEY_TOGGLE_HIDDEN")
            ((hidden_files_show_mode = !hidden_files_show_mode))
            read_current_directory
            scroll_index=0
            window_start_index=0
            cursor_y=0
            draw_screen
            ;;

      esac
      fi

    [[ -t 1 ]] || exit 1

  done

# cleaning up the terminal to original state
  reset_terminal
}

main "$@"
