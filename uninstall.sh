#!/usr/bin/env bash

# uninstall script for bashfm

EXECUTABLE_PATH="/usr/local/bin/bashfm"

if [ -f "$EXECUTABLE_PATH" ]; then
    echo "Found bashfm at $EXECUTABLE_PATH."
    echo "Attempting to remove..."
    sudo rm "$EXECUTABLE_PATH"

    if [ $? -eq 0 ]; then
        echo "Successfully removed $EXECUTABLE_PATH."
    else
        echo "Failed to remove $EXECUTABLE_PATH. Please remove it manually."
    fi
else
    echo "bashfm executable not found at $EXECUTABLE_PATH."
fi


CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bashfm"
USER_CONFIG_FILE="$CONFIG_DIR/config.conf"

if [ -f "$USER_CONFIG_FILE" ]; then
    echo
    echo "Found user config file at $USER_CONFIG_FILE"


    read -p "Do you want to remove your personal config file? [y/N] " response

    # default no
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Removing user config..."
        rm "$USER_CONFIG_FILE"
        echo "User config removed."

        if [ -z "$(ls -A $CONFIG_DIR)" ]; then
            read -p "Config directory is now empty. Remove $CONFIG_DIR? [y/N] " dir_response
            if [[ "$dir_response" =~ ^[Yy]$ ]]; then
                echo "Removing config directory..."
                rmdir "$CONFIG_DIR"
            fi
        fi

    else
        echo "Skipping user config file. Your settings are safe."
    fi
else
    echo "No user config file found at $USER_CONFIG_FILE."
fi

echo
echo "Uninstall complete."