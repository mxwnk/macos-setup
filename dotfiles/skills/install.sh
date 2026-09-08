#!/bin/sh
set -eu

# Skills are installed from their upstream repositories instead of being vendored
# here, so they keep their own licenses. The canonical copy lands in ~/.agents/skills
# and is symlinked into each agent.

npx -y skills add mattpocock/skills \
	-s code-review -s codebase-design -s grill-me -s grill-with-docs \
	-s implement -s prototype -s research -s tdd -s wait-what \
	-g -a claude-code -a opencode -y

npx -y skills add vercel-labs/skills \
	-s find-skills \
	-g -a claude-code -a opencode -y
