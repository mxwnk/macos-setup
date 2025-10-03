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

This repo includes a minimal Hammerspoon setup with Spoons and app bindings.

Point Hammerspoon to this repo's config:

```bash
cd dotfiles
./bootstrap.sh
```

Then open Hammerspoon and click “Reload Config” (or enable automatic reload).
