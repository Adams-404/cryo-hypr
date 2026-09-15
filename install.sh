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
echo "-> Linking/copying configurations..."
cp "$DOTFILES_DIR/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
cp "$DOTFILES_DIR/hypr/scripts/autostart.sh" "$HOME/.config/hypr/scripts/autostart.sh"
chmod +x "$HOME/.config/hypr/scripts/autostart.sh"

cp "$DOTFILES_DIR/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$DOTFILES_DIR/waybar/style.css" "$HOME/.config/waybar/style.css"

cp "$DOTFILES_DIR/wofi/config" "$HOME/.config/wofi/config"
cp "$DOTFILES_DIR/wofi/style.css" "$HOME/.config/wofi/style.css"

cp "$DOTFILES_DIR/mako/config" "$HOME/.config/mako/config"

echo "=== All configs deployed successfully! ==="
