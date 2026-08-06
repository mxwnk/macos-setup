# 🍏 Dev Setup macOS

Welcome! This repo contains my personal macOS dev machine setup, including dotfiles, tools, and automation to get productive fast. 😎

---

## 🛠️ Essential Tools

- 🍺 [Homebrew](https://brew.sh/)
- 📝 [nvchad](https://nvchad.com/) (Neovim config)
- 🧰 [DevToys](https://github.com/ObuchiYuki/DevToysMac.com/)
- 🪟 [Rectangle](https://rectangleapp.com/) (Window manager)
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

This repo includes a minimal Hammerspoon setup with Spoons and app bindings, plus the Ghostty terminal config.

Wire both up to this repo:

```bash
./dotfiles/bootstrap.sh
```

This does two things:

- points Hammerspoon at `dotfiles/hammerspoon/init.lua` (via `defaults write`)
- symlinks `~/.config/ghostty/config` to `dotfiles/ghostty/config` (an existing real file is moved to `config.backup`)

Then open Hammerspoon and click “Reload Config” (or enable automatic reload). Ghostty picks up config changes with `Cmd+Shift+,` (Reload Configuration).
