# ❄️ cryo-hypr

An aesthetic, modern, and fluid **Hyprland** desktop environment configured for Fedora and Linux. Built with a macOS-inspired experience: natural gestures, smooth window animations, dynamic wallpaper-extracted color theming, and a floating glassmorphism status bar.

---

## ✨ Features

- **Compositor**: [Hyprland](https://hyprland.org) with native Lua configuration (`hyprland.lua`).
- **Dynamic Theming**: Automatically extracts color palettes from your active wallpaper to theme Waybar and Wofi.
- **Status Bar**: [Waybar](https://github.com/Alexays/Waybar) with floating pill modules, live **download/upload network bandwidth**, battery health, volume, brightness, clock, and system tray.
- **Spotlight Launcher**: [Wofi](https://hg.sr.ht/~scoopta/wofi) redesigned with a macOS Spotlight aesthetic: centered modal, border-only active highlights, no scrollbars, and background blur/dimming.
- **macOS-like Gestures**:
  - **Natural 2-finger scrolling** and tap-to-click.
  - **3-Finger horizontal swipe** for fluid 1:1 workspace switching.
  - **4-Finger swipe up** to instantly switch wallpapers with animated transitions.
- **Window Controls**: Dedicated Maximize (`SUPER + M`), True Fullscreen (`SUPER + F`), and Minimize to Magic Tray (`SUPER + H` / `SUPER + S`).
- **Wallpaper Engine**: [Awww](https://github.com/the-lost-attic/awww) with animated wipe and grow transitions.
- **Notifications**: [Mako](https://github.com/emersion/mako) styled to match the dark glass aesthetic.
- **Snipping Tool**: Area screenshot straight to clipboard via `SUPER + Shift + S`.

---

## ⌨️ Keybindings Cheat Sheet

### 🚀 Applications & Launcher
| Shortcut | Action |
|---|---|
| `SUPER` or `SUPER + Space` or `SUPER + R` | **Toggle App Launcher** (Wofi Spotlight) |
| `SUPER + Q` | Open Terminal (`kitty`) |
| `SUPER + E` | Open File Manager (`nautilus`) |
| `SUPER + W` | Interactive **Wallpaper Picker** |
| `SUPER + Shift + W` | Cycle **Next Wallpaper** |
| `SUPER + Shift + S` | **Area Screenshot** to clipboard |

### 🪟 Window Management
| Shortcut | Action |
|---|---|
| `SUPER + C` | Close active window |
| `SUPER + M` | **Maximize window** (keeps top status bar) |
| `SUPER + F` | **True Fullscreen** |
| `SUPER + H` | **Minimize / Hide window** (sends to magic tray) |
| `SUPER + S` | **Show / Toggle Minimized tray** |
| `SUPER + V` | Toggle floating mode |
| `SUPER + J` | Toggle split layout |
| `SUPER + Arrow Keys` | Move window focus |
| `SUPER + Mouse Drag` | Move window (Left Click) / Resize (Right Click) |

### 🌐 Workspaces & Navigation
| Shortcut | Action |
|---|---|
| `SUPER + 1-9` | Switch to Workspace 1-9 |
| `SUPER + Shift + 1-9` | Move active window to Workspace 1-9 |
| `SUPER + Escape` | Exit session / Power menu |

---

## 👆 Touchpad Gestures

* **2-Finger Scroll**: Natural scrolling (content moves with your fingers).
* **3-Finger Swipe (Left / Right)**: Fluid, animated 1:1 workspace switching.
* **4-Finger Swipe (Up)**: Randomly switch wallpaper with a smooth animated wipe and instant color scheme adaptation!

---

## 🚀 Quick Installation

Clone this repository and run the automated installer:

```bash
git clone https://github.com/Adams-404/cryo-hypr.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
1. Detect your package manager (`dnf` or `pacman`) and install required packages & fonts.
2. Back up any existing configs to `~/.config_backup_<timestamp>`.
3. Create live symlinks from `~/.config/{hypr,waybar,wofi,mako}` directly to `~/dotfiles/`.
4. Make all scripts executable and reload Hyprland live.

---

## 📁 Repository Structure

```
~/dotfiles/
├── hypr/
│   ├── hyprland.lua            # Main Hyprland Lua configuration
│   └── scripts/
│       ├── autostart.sh        # Boot lifecycle daemon manager
│       ├── menu.sh             # Toggleable launcher script
│       ├── wallpaper.sh        # Wallpaper rotator and interactive picker
│       └── extract_colors.py   # Wallpaper color extractor (PIL)
├── waybar/
│   ├── config.jsonc            # Modular status bar layout & network speeds
│   ├── style.css               # Glassmorphism pill styling
│   └── colors.css              # Dynamic wallpaper palette
├── wofi/
│   ├── config                  # Spotlight modal configuration
│   ├── style.css               # Border-only active state & no scrollbars
│   └── colors.css              # Dynamic wallpaper palette
├── mako/
│   └── config                  # Dark glass notification theme
├── install.sh                  # Automated multi-distro setup script
└── README.md                   # Documentation & keybinding guide
```

---

## 🖼️ Adding Custom Wallpapers

Simply drop any `.png`, `.jpg`, or `.jpeg` images into your `~/Pictures/Wallpapers` folder:
```bash
cp your_image.png ~/Pictures/Wallpapers/
```
Press **`SUPER + W`** to pick it from the launcher, or swipe **4 fingers up** on your trackpad to cycle through your wallpapers!
