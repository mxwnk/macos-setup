# 🍏 Dev Setup macOS

Welcome! This repo contains my personal macOS dev machine setup, including dotfiles, tools, and automation to get productive fast. 😎

---

## 🛠️ Essential Tools

- 🍺 [Homebrew](https://brew.sh/)
- 👻 [Ghostty](https://ghostty.org/) (Terminal)
- 🔨 [Hammerspoon](https://www.hammerspoon.org/) (Automation)
- 🔀 [Flip](https://github.com/mxwnk/flip) (Window switcher)
- 🔐 [1Password](https://1password.com/)
- 📄 [PDFExpert](https://pdfexpert.com/)
- 🎨 [Pikka](https://www.pikka.app/) (Color picker)
- 🗂️ [Marta](https://marta.sh/) (File manager)

---

## 🍺 Brew Setup

Install all dependencies with:

```
brew bundle --file ./Brewfile
```

---

## 🍏 macOS Preferences

A skeleton script configuring common macOS system defaults (Finder, Dock, fast keyboard repeat rate, Screenshots destination, etc.):

```bash
./macos/defaults.sh
```

The script applies every setting it contains and restarts Finder, Dock and SystemUIServer at the end — read it and adjust the values before running it. Some changes only take effect after a logout.

---

## ⚙️ Dotfiles

One script wires everything into place:

```bash
./dotfiles/bootstrap.sh
```

It symlinks these into `$HOME`, moving an existing real file to `<name>.backup` first. Paths are relative to the repository root:

| Repo file                        | Destination                           |
| -------------------------------- | ------------------------------------- |
| `dotfiles/ghostty/config`        | `~/.config/ghostty/config`            |
| `dotfiles/zsh/zshrc`             | `~/.zshrc`                            |
| `dotfiles/git/gitconfig`         | `~/.gitconfig`                        |
| `dotfiles/git/gitignore_global`  | `~/.gitignore_global`                 |
| `dotfiles/cmux/cmux.json`        | `~/.config/cmux/cmux.json`            |
| `dotfiles/zed/settings.json`     | `~/.config/zed/settings.json`         |
| `dotfiles/agents/AGENTS.md`      | `~/.config/opencode/AGENTS.md`        |
| `dotfiles/agents/AGENTS.md`      | `~/.claude/CLAUDE.md`                 |
| `dotfiles/opencode/opencode.json`| `~/.config/opencode/opencode.json`    |
| `dotfiles/opencode/tui.jsonc`    | `~/.config/opencode/tui.jsonc`        |
| `dotfiles/opencode/commands`     | `~/.config/opencode/commands`         |
| `dotfiles/claude/settings.json`  | `~/.claude/settings.json`             |
| `dotfiles/claude/commands`       | `~/.claude/commands`                  |
| `skills/jira`                    | `~/.claude/skills/jira`               |

Hammerspoon is the exception: it reads its config path from a preference, so the script points it at `dotfiles/hammerspoon/init.lua` via `defaults write` instead of symlinking.

Afterwards, open Hammerspoon and click "Reload Config" (or enable automatic reload). Ghostty picks up config changes with `Cmd+Shift+,` (Reload Configuration), opencode needs a restart.

### 🔒 Machine-local files

These stay outside the repo because they hold identities and secrets. The bootstrap script lists them again at the end:

- `~/.secrets.zsh` — API tokens, sourced by `.zshrc`
- `~/.zshrc.local` — machine-specific `PATH` entries and `OPENCODE_GHE_URL`
- `~/.gitconfig.local` — git identity, included last by `.gitconfig` so its values win
- `~/.config/.jira/.config.yml` — jira-cli server and login for `/jira`; create it with `jira init`. The token itself belongs in `~/.secrets.zsh` as `JIRA_API_TOKEN`

---

## 🤖 Agent Skills

Third-party skills are not vendored here, they are installed from their upstream repositories so they keep their own licenses:

```bash
sh skills/install.sh
```

The canonical copy lands in `~/.agents/skills/`, which Claude Code and opencode both read.

Own skills live in this repo and are symlinked by the bootstrap script — currently `skills/jira`, which fetches a Jira issue with `jira-cli` and works out an approach before any code gets written:

```
/jira TEST-123
```

Claude Code exposes every skill as a slash command by itself (`/tdd`, `/code-review`), so `dotfiles/claude/commands` only holds commands that are not skills. opencode needs the thin wrappers in `dotfiles/opencode/commands` for the same effect — `jira.md` is one of them.
