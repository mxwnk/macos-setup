#!/bin/sh
set -eu

# Resolve the directory this script lives in, so it can be run from anywhere.
DOTFILES=$(cd "$(dirname "$0")" && pwd)

# --- Hammerspoon ---
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$DOTFILES/hammerspoon/init.lua"
echo "Hammerspoon config -> $DOTFILES/hammerspoon/init.lua"

# --- Ghostty ---
GHOSTTY_DIR="$HOME/.config/ghostty"
GHOSTTY_CONFIG="$GHOSTTY_DIR/config"
mkdir -p "$GHOSTTY_DIR"

if [ -L "$GHOSTTY_CONFIG" ]; then
	rm "$GHOSTTY_CONFIG"
elif [ -e "$GHOSTTY_CONFIG" ]; then
	# Keep a copy of a pre-existing real file instead of silently dropping it.
	backup="$GHOSTTY_CONFIG.backup"
	mv "$GHOSTTY_CONFIG" "$backup"
	echo "Existing Ghostty config moved to $backup"
fi

ln -s "$DOTFILES/ghostty/config" "$GHOSTTY_CONFIG"
echo "Ghostty config -> $DOTFILES/ghostty/config"
