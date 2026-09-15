#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Hyprland Dotfiles Setup ==="

# Create config directories
mkdir -p "$HOME/.config/hypr/scripts"
mkdir -p "$HOME/.config/waybar"
mkdir -p "$HOME/.config/wofi"
mkdir -p "$HOME/.config/mako"

# Copy configurations
echo "-> Deploying configurations..."
cp "$DOTFILES_DIR/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
cp "$DOTFILES_DIR/hypr/scripts/autostart.sh" "$HOME/.config/hypr/scripts/autostart.sh"
cp "$DOTFILES_DIR/hypr/scripts/menu.sh" "$HOME/.config/hypr/scripts/menu.sh"
cp "$DOTFILES_DIR/hypr/scripts/extract_colors.py" "$HOME/.config/hypr/scripts/extract_colors.py"
chmod +x "$HOME/.config/hypr/scripts/autostart.sh" "$HOME/.config/hypr/scripts/menu.sh" "$HOME/.config/hypr/scripts/extract_colors.py"

cp "$DOTFILES_DIR/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$DOTFILES_DIR/waybar/style.css" "$HOME/.config/waybar/style.css"
[ -f "$DOTFILES_DIR/waybar/colors.css" ] && cp "$DOTFILES_DIR/waybar/colors.css" "$HOME/.config/waybar/colors.css"

cp "$DOTFILES_DIR/wofi/config" "$HOME/.config/wofi/config"
cp "$DOTFILES_DIR/wofi/style.css" "$HOME/.config/wofi/style.css"
[ -f "$DOTFILES_DIR/wofi/colors.css" ] && cp "$DOTFILES_DIR/wofi/colors.css" "$HOME/.config/wofi/colors.css"

cp "$DOTFILES_DIR/mako/config" "$HOME/.config/mako/config"

echo "=== All configs deployed successfully! ==="
