# AGENT INSTRUCTIONS: cryo-hypr Maintenance & Development

This file serves as a mandatory guideline for any AI assistant or autonomous agent working on the `cryo-hypr` dotfiles repository.

---

## 1. The Documentation Mandate (CRITICAL)

> **Whenever any configuration, keybinding, gesture, script, style, or module is added, modified, or removed, you MUST immediately update the documentation (`README.md`, installation script, and cheat sheets) to match.**

- The docs must **never** lag behind the code.
- If you add a keybinding, document it in the Keybindings table in `README.md`.
- If you modify or add a script, document its usage and parameters.
- If you change gestures or window management behavior, update the Touchpad Gestures section.
- If you add or remove dependencies, update both `install.sh` and `README.md`.

---

## 2. Architecture & Single Source of Truth

- All configuration files belong in `~/cryo-hypr` (with `~/dotfiles` preserved as a backward-compatibility symlink):
  - `~/cryo-hypr/hypr/` -> symlinked to `~/.config/hypr`
  - `~/cryo-hypr/waybar/` -> symlinked to `~/.config/waybar`
  - `~/cryo-hypr/swaync/` -> symlinked to `~/.config/swaync`
  - `~/cryo-hypr/wofi/` -> symlinked to `~/.config/wofi`
  - `~/cryo-hypr/rofi/` -> symlinked to `~/.config/rofi`
  - `~/cryo-hypr/mako/` -> symlinked to `~/.config/mako`
- **Never** break or replace symlinks with plain directories. Edit files inside `~/cryo-hypr/` so that every change is immediately tracked by Git.
- Always ensure scripts in `hypr/scripts/` have executable permissions (`chmod +x`).

---

## 3. Verification & Zero-Error Policy

Before considering any task complete:
1. Reload Hyprland: `hyprctl reload`
2. Check for syntax or schema errors: `hyprctl configerrors` (must return empty/zero errors).
3. If any previous notifications or error bars linger on screen, dismiss them: `hyprctl dismissnotify`.
4. Check that core daemons (`waybar`, `mako`, `awww-daemon`) are running: `pgrep -a waybar; pgrep -a mako; pgrep -a awww`.

---

## 4. Git & Commit Workflow

- Keep commits granular, clean, and feature-based following Conventional Commits:
  - `feat(...)`: new functionality, keybinds, or modules
  - `fix(...)`: bug fixes, syntax corrections, schema adjustments
  - `style(...)`: CSS styling, theme changes, visual polish
  - `docs(...)`: documentation, README, or agent guideline updates
  - `chore(...)`: maintenance, installer script, or symlink updates
- Push all changes to the remote repository on `origin main` (`Adams-404/cryo-hypr`).

---

## 5. Strict GNOME Isolation Mandate (CRITICAL)

> **GNOME is the user's stable fallback desktop environment. You MUST NEVER modify, touch, or interfere with GNOME settings, daemons, or configurations.**

- **NEVER** run `gsettings set` or `dconf write` targeting global GNOME schemas (`org.gnome.desktop.*`, `org.gnome.shell.*`, `org.gnome.mutter.*`).
- **NEVER** launch `gnome-control-center` with `XDG_CURRENT_DESKTOP=GNOME` or hook GNOME Settings into Hyprland scripts/menus.
- **NEVER** alter GNOME titlebar buttons (`button-layout`), GNOME text scaling (`text-scaling-factor`), or GNOME extensions.
- All configurations, font sizes, glass themes, color palettes, and window rules MUST be strictly isolated within `~/cryo-hypr` (`hypr`, `waybar`, `swaync`, `wofi`, `rofi`, and `mako`).
