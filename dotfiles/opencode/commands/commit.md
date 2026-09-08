---
description: Create a concise, single-line conventional commit
---

Commit the current changes following these strict rules:

1. Inspect changes:
   - Run `git status` to see staged and unstaged changes.
   - Inspect `git diff --cached` (or `git diff` if nothing is staged yet).
   - If there are no changes to commit, stop and inform the user.

2. Stage files:
   - If changes are already staged, respect the staged selection.
   - If nothing is staged, stage the relevant modified files (`git add <files>`).
   - Never stage secrets, credentials, or unrelated untracked files.

3. Commit message requirements:
   - Format: `<type>(<scope>): <description>` or `<type>: <description>`.
   - Allowed types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`.
   - Scope should be concise and reflect the affected component or area.
   - Strictly SINGLE LINE only. Never add a commit body, blank lines, bullet points, footers, or explanations.
   - Maximum 72 characters.
   - Written in English, imperative mood (e.g., "add", "fix", "refactor", not "added" or "adds").
   - If user provided arguments ($ARGUMENTS), incorporate them as context or preferred message hint.

4. Execute:
   - Run `git commit -m "<message>"`.
   - Report only the commit hash and the commit message.
