#!/usr/bin/env bash
# ==============================================================================
#  cryo-hypr: Automated Dotfiles Installer for Hyprland
#  Supports: Fedora (dnf), Arch Linux (pacman), Debian/Ubuntu (apt)
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo -e "${BLUE}=== Welcome to cryo-hypr Setup ===${RESET}"
echo "Dotfiles directory: $DOTFILES_DIR"

# 1. Package Installation (Optional / Interactive)
install_packages() {
    echo -e "${BLUE}-> Detecting package manager...${RESET}"
    if command -v dnf >/dev/null 2>&1; then
        echo -e "${GREEN}Detected Fedora (dnf). Installing dependencies...${RESET}"
        sudo dnf install -y \
            waybar \
            wofi \
            mako \
            SwayNotificationCenter \
            brightnessctl \
            pavucontrol \
            network-manager-applet \
            grim \
            slurp \
            wl-clipboard \
            python3-pillow \
            python3-gobject \
            gtk-layer-shell \
            jetbrains-mono-fonts-all \
            fontawesome-6-free-fonts \
            fontawesome-6-brands-fonts
    elif command -v pacman >/dev/null 2>&1; then
        echo -e "${GREEN}Detected Arch Linux. Installing dependencies...${RESET}"
        sudo pacman -S --needed --noconfirm \
            waybar \
            wofi \
            mako \
            swaynotificationcenter \
            brightnessctl \
            pavucontrol \
            network-manager-applet \
            grim \
            slurp \
            wl-clipboard \
            python-pillow \
            python-gobject \
            gtk-layer-shell \
            ttf-jetbrains-mono \
            ttf-font-awesome
    else
        echo -e "${YELLOW}Please ensure waybar, wofi, mako, awww, and fonts are installed.${RESET}"
    fi
}

read -rp "Do you want to install/verify system packages? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    install_packages
fi

# 2. Backup existing configs if they are real directories (not symlinks)
echo -e "${BLUE}-> Backing up existing configurations...${RESET}"
mkdir -p "$BACKUP_DIR"
for cfg in hypr waybar wofi mako rofi swaync; do
    if [ -d "$HOME/.config/$cfg" ] && [ ! -L "$HOME/.config/$cfg" ]; then
        echo "Backing up ~/.config/$cfg -> $BACKUP_DIR/"
        mv "$HOME/.config/$cfg" "$BACKUP_DIR/"
    elif [ -L "$HOME/.config/$cfg" ]; then
        rm "$HOME/.config/$cfg"
    fi
done

# 3. Create symlinks directly to dotfiles
echo -e "${BLUE}-> Linking dotfiles into ~/.config/...${RESET}"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
ln -sf "$DOTFILES_DIR/waybar" "$HOME/.config/waybar"
ln -sf "$DOTFILES_DIR/wofi" "$HOME/.config/wofi"
ln -sf "$DOTFILES_DIR/mako" "$HOME/.config/mako"
ln -sf "$DOTFILES_DIR/rofi" "$HOME/.config/rofi"
ln -sf "$DOTFILES_DIR/swaync" "$HOME/.config/swaync"

# 4. Set execution permissions on scripts and compile IPC shim
echo -e "${BLUE}-> Setting script permissions and compiling Waybar IPC shim...${RESET}"
chmod +x "$DOTFILES_DIR/hypr/scripts/"*
if command -v gcc >/dev/null 2>&1; then
    [ -f "$DOTFILES_DIR/waybar/hypr_compat.c" ] && gcc -shared -fPIC -O2 -Wall "$DOTFILES_DIR/waybar/hypr_compat.c" -o "$DOTFILES_DIR/waybar/hypr_compat.so" -ldl 2>/dev/null || true
    [ -f "$DOTFILES_DIR/hypr/scripts/ws_scroll.c" ] && gcc -O3 -Wall "$DOTFILES_DIR/hypr/scripts/ws_scroll.c" -o "$DOTFILES_DIR/hypr/scripts/ws_scroll" 2>/dev/null || true
fi

# 5. Initialize colors and wallpaper if Pictures/Wallpapers exists
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
if [ -d "$WALLPAPER_DIR" ]; then
    FIRST_WALL=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)
    if [ -n "$FIRST_WALL" ]; then
        echo -e "${BLUE}-> Generating initial color palette from $FIRST_WALL...${RESET}"
        python3 "$DOTFILES_DIR/hypr/scripts/extract_colors.py" "$FIRST_WALL"
    fi
fi

# 6. Reload Hyprland if active
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo -e "${GREEN}-> Reloading active Hyprland session...${RESET}"
    hyprctl reload || true
fi

echo -e "${GREEN}=== cryo-hypr installation complete! Enjoy your new desktop! ===${RESET}"
