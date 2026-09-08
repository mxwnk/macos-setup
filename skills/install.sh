#!/bin/sh
set -eu

npx -y skills add mattpocock/skills \
	-s code-review \
	-s implement \
	-s codebase-design \
	-s grill-me \
	-s grill-with-docs \
	-s prototype \
	-s research \
	-s tdd \
	-s wait-what \
	-g -a claude-code -a opencode -y

npx -y skills add vercel-labs/skills \
	-s find-skills \
	-g -a claude-code -a opencode -y
