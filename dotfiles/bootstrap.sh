#!/bin/sh
set -eu

# Resolve the directory this script lives in, so it can be run from anywhere.
DOTFILES=$(cd "$(dirname "$0")" && pwd)

# Symlink a file from this repo into place, preserving anything already there.
link() {
	src="$DOTFILES/$1"
	dst="$HOME/$2"

	if [ ! -e "$src" ]; then
		echo "skip $2 (missing $1)"
		return
	fi

	mkdir -p "$(dirname "$dst")"

	if [ -L "$dst" ]; then
		rm "$dst"
	elif [ -e "$dst" ]; then
		mv "$dst" "$dst.backup"
		echo "     existing $2 moved to $2.backup"
	fi

	ln -s "$src" "$dst"
	echo "link $2 -> $src"
}

link ghostty/config          .config/ghostty/config
link zsh/zshrc               .zshrc
link git/gitconfig           .gitconfig
link git/gitignore_global    .gitignore_global

link opencode/opencode.json  .config/opencode/opencode.json
link opencode/tui.jsonc      .config/opencode/tui.jsonc
link opencode/AGENTS.md      .config/opencode/AGENTS.md
link opencode/commands       .config/opencode/commands
link opencode/skills         .config/opencode/skills

# Hammerspoon reads its config path from a preference, so it needs no symlink.
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$DOTFILES/hammerspoon/init.lua"
echo "pref Hammerspoon -> $DOTFILES/hammerspoon/init.lua"

cat <<'EOF'

Machine-local files are not managed here and must exist separately:
  ~/.secrets.zsh      API tokens sourced by .zshrc
  ~/.zshrc.local      machine-specific PATH entries and OPENCODE_GHE_URL
  ~/.gitconfig.local  git identity, included by .gitconfig
EOF
