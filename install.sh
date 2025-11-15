#!/usr/bin/env bash

# install script for bashfm
# Note :this will install the files to /usr/local/bin

echo "Installing bashfm to /usr/local/bin..."

sudo cp ./src/main.sh /usr/local/bin/bashfm
sudo chmod +x /usr/local/bin/bashfm


CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bashfm"
USER_CONFIG_FILE="$CONFIG_DIR/config.conf"
DEFAULT_CONFIG_FILE="./config/config.conf"

echo "Creating config directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"

# this will copy the default config if not already made
if [ ! -f "$USER_CONFIG_FILE" ]; then
    echo "No user config found. Copying default config..."
    cp "$DEFAULT_CONFIG_FILE" "$USER_CONFIG_FILE"
else
    echo "User config already exists at $USER_CONFIG_FILE. Skipping copy."
fi

echo "Install complete! Run with 'bashfm'"