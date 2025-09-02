#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/source/dotfiles"

copy_config() {
    local app_name=$1
    local src="$CONFIG_DIR/$app_name"
    local dest="$DOTFILES_DIR/$app_name"

    if [ -d "$src" ]; then
        echo "Copying $app_name configuration..."
        rsync -av --delete "$src/" "$dest/"
        echo "$app_name copied to $dest"
    else
        echo "No configuration found for $app_name at $src"
    fi
}

copy_config "nvim"
copy_config "wezterm"
copy_config "awesome"

echo "All configurations have been synced to $DOTFILES_DIR"
