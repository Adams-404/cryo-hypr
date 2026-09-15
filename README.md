# Hyprland Dotfiles (Fedora Linux)

A clean, modern, and aesthetic Hyprland desktop environment configured for Fedora. Featuring a floating glassmorphism status bar, smooth wallpaper transitions, dark Tokyo Night theme, and intuitive keybindings.

## ✨ Features

- **Window Manager**: [Hyprland](https://hyprland.org) with Lua configuration (`hyprland.lua`)
- **Status Bar**: [Waybar](https://github.com/Alexays/Waybar) with floating pill modules, workspace indicators, audio, brightness, battery, WiFi, and power controls
- **App Launcher**: [Wofi](https://hg.sr.ht/~scoopta/wofi) with centered dark translucent modal, app icons, and JetBrains Mono typography
- **Wallpaper Daemon**: [Awww](https://github.com/the-lost-attic/awww) with smooth animated wipes and transitions
- **Notifications**: [Mako](https://github.com/emersion/mako) styled to match the dark aesthetic
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Screenshots**: [Grim](https://gitlab.freedesktop.org/emersion/grim) + [Slurp](https://github.com/emersion/slurp) + [wl-clipboard](https://github.com/bugaevc/wl-clipboard)

---

## ⌨️ Keybindings

| Keybinding | Action |
|---|---|
| `SUPER` or `SUPER + Space` or `SUPER + R` | Open App Launcher (Wofi) |
| `SUPER + Q` | Launch Terminal (Kitty) |
| `SUPER + E` | Open File Manager (Nautilus) |
| `SUPER + C` | Close Active Window |
| `SUPER + V` | Toggle Window Floating Mode |
| `SUPER + Shift + S` | Area Screenshot to Clipboard |
| `SUPER + 1-9` | Switch Workspace 1-9 |
| `SUPER + Shift + 1-9` | Move Window to Workspace 1-9 |
| `SUPER + Arrow Keys` | Move Focus |
| `SUPER + Mouse Drag` | Move Window (Left Click) / Resize (Right Click) |
| `SUPER + M` | Exit / Power Menu |

---

## 🚀 Installation

Clone this repository and run the install script:

```bash
git clone https://github.com/<username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Restart or reload Hyprland:
```bash
hyprctl reload
```
