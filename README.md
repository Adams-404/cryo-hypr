# cryo-hypr

An aesthetic, modern, and fluid **Hyprland** desktop environment configured for Fedora and Linux. Built with a macOS-inspired experience: natural gestures, smooth window animations, dynamic wallpaper-extracted color theming, and a floating glassmorphism status bar.

---

## Features

- **Compositor**: [Hyprland](https://hyprland.org) with native Lua configuration (`hyprland.lua`).
- **Dynamic Theming**: Automatically extracts color palettes from your active wallpaper to theme Waybar and Wofi.
- **Status Bar**: [Waybar](https://github.com/Alexays/Waybar) with floating pill modules, live **download/upload network bandwidth**, battery health, volume, brightness, clock, settings, and system tray.
- **Spotlight Launcher**: [Wofi](https://hg.sr.ht/~scoopta/wofi) redesigned with a macOS Spotlight aesthetic: centered modal, border-only active highlights, no scrollbars, and background blur/dimming.
- **macOS-like Gestures**:
  - **Natural 2-finger scrolling** and tap-to-click.
  - **3-Finger horizontal swipe** for fluid 1:1 workspace switching.
  - **4-Finger swipe up** to instantly switch wallpapers with animated transitions.
- **Window Controls**: Dedicated Maximize (`SUPER + M`), True Fullscreen (`SUPER + F`), and Minimize to Magic Tray (`SUPER + H` / `SUPER + S`).
- **Wallpaper Chooser**: Custom GTK3 Layer-Shell wallpaper picker with two-column layout, real-time right-panel image preview, and live desktop preview sync.
- **Global Font Scaling**: Dynamic font and scaling controller (`fontsize.sh`) to easily adjust UI size across GTK, Waybar, Wofi, and notifications.
- **Notification & Control Center**: [SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter) slide-out side panel with notification history, Do Not Disturb, MPRIS media controls, volume/brightness sliders, and unread counter badge on the status bar.
- **Snipping Tool**: Area screenshot straight to clipboard via the physical **`Print`** (PrtSc) key.

---

## Keybindings Cheat Sheet

### Applications & Launcher
| Shortcut | Action |
|---|---|
| `SUPER` or `SUPER + Space` or `SUPER + R` | **Toggle App Launcher** (Wofi Spotlight) |
| `SUPER + I` or `SUPER + ,` | **Settings & Preferences Hub** (Theme Accent Color, Glass Blur, Wallpaper, Font Size, Wi-Fi, Audio) |
| `SUPER + N` | **Toggle Notification Center** slide-out side panel (or click bell on Waybar) |
| `SUPER + Shift + N` | Interactive **Wi-Fi / Network Dropdown** (or click Network pill on Waybar) |
| `SUPER + Q` | Open Terminal (`kitty`) |
| `SUPER + E` | Open File Manager (`nautilus`) |
| `SUPER + W` | Interactive **Wallpaper Picker** (live preview card on the right, live background sync, press again to cancel) |
| `SUPER + Shift + W` | Cycle **Next Wallpaper** |
| `SUPER + B` | **Glass / Blur Theme Switcher** (`Liquid`, `Frosted`, `Crystal`, `Deep`, `Off`) |
| `Print` (PrtSc) | **Area Screenshot** to clipboard (press again or Escape to cancel) |

### Window Management
| Shortcut | Action |
|---|---|
| `SUPER + Tab` | **Visual window switcher** (Rofi window modal) |
| `SUPER + C` | Close active window |
| `SUPER + M` | **Maximize window** (keeps top status bar) |
| `SUPER + F` | **True Fullscreen** |
| `SUPER + V` | Toggle floating mode |
| `SUPER + J` | Toggle split layout |
| `SUPER + Arrow Keys` | Move window focus |
| `SUPER + Mouse Drag` | **Smart Drag Window**: Drag across screen, drag to left/right edge to shift workspaces, or drop onto top status bar workspace buttons (1-5)! |
| `SUPER + Shift + Left / Right` | Move active window to previous / next workspace |

### Workspaces & Navigation
| Shortcut | Action |
|---|---|
| `ALT + Tab` | **Cycle forward between workspaces** |
| `ALT + Shift + Tab` | **Cycle backward between workspaces** |
| `SUPER + 1-9` | Switch to Workspace 1-9 |
| `SUPER + Shift + 1-9` | Move active window to Workspace 1-9 |
| `SUPER + Scroll Up / Down` | Scroll through workspaces |
| `Hover Status Bar + Scroll Up / Down` | **Scroll through workspaces** anywhere on the status bar (smooth gesture-like switching) |
| `Hover Workspace + 2-Finger Slide Left / Right` | **Slide through workspaces** horizontally on the workspace buttons or status bar |
| `SUPER + Left Click Drag to Edge` | Drag window to left edge to move to next workspace (`ws + 1`) or right edge for previous (`ws - 1`) |
| `SUPER + Drop onto Status Bar` | Drop dragged window onto workspace button (1-5) on Waybar to place it there |
| `SUPER + Escape` | Exit session / Power menu |

---

## Touchpad Gestures

* **2-Finger Scroll / Slide**:
  * **In Applications**: Natural scrolling (content moves with your fingers, macOS style).
  * **On Top Status Bar / Workspaces**: Slide left or right with 2 fingers to cycle between workspaces smoothly (slide left = next, slide right = previous).
* **3-Finger Swipe (Left / Right)**: Fluid, animated 1:1 workspace switching. Continuous scrolling enabled—swipe through existing workspaces or seamlessly into a **fresh new workspace** if no apps are there!
* **Wallpaper Switching**: Press `SUPER + W` to select from the live preview picker, or `SUPER + Shift + W` for the next wallpaper.

---

## Quick Installation

Clone this repository and run the automated installer:

```bash
git clone https://github.com/Adams-404/cryo-hypr.git ~/cryo-hypr
cd ~/cryo-hypr
./install.sh
```

The installer will:
1. Detect your package manager (`dnf` or `pacman`) and install required packages & fonts.
2. Back up any existing configs to `~/.config_backup_<timestamp>`.
3. Create live symlinks from `~/.config/{hypr,waybar,wofi,swaync,rofi}` directly to `~/cryo-hypr/`.
4. Make all scripts executable and reload Hyprland live.

---

## Repository Structure

```
~/cryo-hypr/
├── hypr/
│   ├── hyprland.lua            # Main Hyprland Lua configuration
│   └── scripts/
│       ├── autostart.sh        # Boot lifecycle daemon manager
│       ├── settings.sh         # Unified Settings & Preferences hub
│       ├── theme_color.sh      # Theme accent color selector (manual or auto)
│       ├── fontsize.sh         # Global font scaling controller
│       ├── glass.sh            # Glassmorphism & blur level switcher (persistent)
│       ├── wifi.sh             # Interactive Wi-Fi manager
│       ├── screenshot.sh       # PrtSc area screenshot with cancel toggle
│       ├── menu.sh             # Toggleable launcher script
│       ├── wallpaper.sh        # Wallpaper rotator and picker launcher
│       ├── wallpaper_picker.py # Modern GTK3 layer-shell wallpaper chooser with preview
│       └── extract_colors.py   # Wallpaper color extractor (PIL)
├── waybar/
│   ├── config.jsonc            # Modular status bar layout & network speeds
│   ├── style.css               # Glassmorphism pill styling
│   └── colors.css              # Dynamic wallpaper palette
├── swaync/
│   ├── config.json             # Notification center layout & toggles
│   ├── style.css               # Floating glassmorphism notification center
│   └── colors.css              # Dynamic theme color palette
├── wofi/
│   ├── config                  # Spotlight modal configuration
│   ├── style.css               # Border-only active state & no scrollbars
│   └── colors.css              # Dynamic wallpaper palette
├── mako/
│   └── config                  # Dark glass notification theme (fallback)
├── rofi/
│   └── config.rasi             # Modern window switcher modal
├── install.sh                  # Automated multi-distro setup script
├── AGENT.md                    # Mandatory AI maintenance guidelines
└── README.md                   # Documentation & keybinding guide
```

---

## Adding Custom Wallpapers

Simply drop any `.png`, `.jpg`, or `.jpeg` images into your `~/Pictures/Wallpapers` folder:
```bash
cp your_image.png ~/Pictures/Wallpapers/
```
Press **`SUPER + W`** to pick it from the interactive live preview chooser, or swipe **4 fingers up** on your trackpad to cycle through your wallpapers!
