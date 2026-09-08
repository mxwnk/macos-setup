# 🍏 Dev Setup macOS

Welcome! This repo contains my personal macOS dev machine setup, including dotfiles, tools, and automation to get productive fast. 😎

---

## 🛠️ Essential Tools

- 🍺 [Homebrew](https://brew.sh/)
- 👻 [Ghostty](https://ghostty.org/) (Terminal)
- 🔨 [Hammerspoon](https://www.hammerspoon.org/) (Automation & window management)
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

## ⚙️ Dotfiles

Everything under `dotfiles/` is wired into place by one script:

```bash
./dotfiles/bootstrap.sh
```

It symlinks these into `$HOME`, moving an existing real file to `<name>.backup` first:

| Repo file                     | Destination                           |
| ----------------------------- | ------------------------------------- |
| `ghostty/config`              | `~/.config/ghostty/config`            |
| `zsh/zshrc`                   | `~/.zshrc`                            |
| `git/gitconfig`               | `~/.gitconfig`                        |
| `git/gitignore_global`        | `~/.gitignore_global`                 |
| `opencode/opencode.json`      | `~/.config/opencode/opencode.json`    |
| `opencode/tui.jsonc`          | `~/.config/opencode/tui.jsonc`        |
| `opencode/AGENTS.md`          | `~/.config/opencode/AGENTS.md`        |
| `opencode/commands`           | `~/.config/opencode/commands`         |
| `claude/commands`             | `~/.claude/commands`                  |

Hammerspoon is the exception: it reads its config path from a preference, so the script points it at `dotfiles/hammerspoon/init.lua` via `defaults write` instead of symlinking.

Afterwards, open Hammerspoon and click "Reload Config" (or enable automatic reload). Ghostty picks up config changes with `Cmd+Shift+,` (Reload Configuration), opencode needs a restart.

### 🔒 Machine-local files

These stay outside the repo because they hold identities and secrets. The bootstrap script lists them again at the end:

- `~/.secrets.zsh` — API tokens, sourced by `.zshrc`
- `~/.zshrc.local` — machine-specific `PATH` entries and `OPENCODE_GHE_URL`
- `~/.gitconfig.local` — git identity, included last by `.gitconfig` so its values win

---

## 🤖 Agent Skills

Skills are not vendored here, they are installed from their upstream repositories so they keep their own licenses:

```bash
sh skills/install.sh
```

The canonical copy lands in `~/.agents/skills/`, which Claude Code and opencode both read.

Claude Code exposes every skill as a slash command by itself (`/tdd`, `/code-review`), so `claude/commands` only holds commands that are not skills. opencode needs the thin wrappers in `opencode/commands` for the same effect.
