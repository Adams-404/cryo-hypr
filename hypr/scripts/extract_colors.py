#!/usr/bin/env python3
import sys
import os
import re
import colorsys
import subprocess
from PIL import Image

Image.MAX_IMAGE_PIXELS = None

HOME = os.path.expanduser("~")
THEME_COLOR_FILE = os.path.join(HOME, ".config/hypr/theme_color")
GLASS_PRESET_FILE = os.path.join(HOME, ".config/hypr/glass_preset")
CACHE_DIR = os.path.join(HOME, ".cache/wallpaper_picker")

def get_glass_opacities():
    preset = "liquid"
    if os.path.exists(GLASS_PRESET_FILE):
        try:
            with open(GLASS_PRESET_FILE, "r") as f:
                val = f.read().strip().lower()
                if val in ("liquid", "frosted", "crystal", "deep", "off"):
                    preset = val
        except Exception:
            pass

    opacities = {
        "liquid": (0.48, 0.60),
        "frosted": (0.72, 0.82),
        "crystal": (0.32, 0.45),
        "deep": (0.85, 0.90),
        "off": (0.92, 0.92),
    }
    return opacities.get(preset, (0.48, 0.60))

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 6:
        return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    return (122, 162, 247)

def get_manual_color():
    if os.path.exists(THEME_COLOR_FILE):
        try:
            with open(THEME_COLOR_FILE, "r") as f:
                val = f.read().strip()
                if re.match(r"^#[0-9a-fA-F]{6}$", val):
                    return val
        except Exception:
            pass
    return None

def extract_dominant_accent(image_path):
    # Try fast cached preview first
    base_name = os.path.basename(image_path)
    cached_thumb = os.path.join(CACHE_DIR, f"prev_{base_name}.jpg")
    
    img = None
    if os.path.isfile(cached_thumb):
        try:
            img = Image.open(cached_thumb).convert("RGB")
        except Exception:
            img = None

    if img is None and os.path.isfile(image_path):
        try:
            with Image.open(image_path) as im:
                im.draft('RGB', (200, 200))
                img = im.convert("RGB").resize((160, 160))
        except Exception as e:
            print(f"Error loading image: {e}")
            return (122, 162, 247)

    if img is None:
        return (122, 162, 247)

    try:
        quantized = img.convert("P", palette=Image.Palette.ADAPTIVE, colors=24).convert("RGB")
        colors = quantized.getcolors(maxcolors=256)
        if not colors:
            return (122, 162, 247)

        scored = []
        for count, (r, g, b) in colors:
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            # Filter pure blacks, dark grays, and pure whites
            if v < 0.18 or (s < 0.14 and v > 0.85):
                continue
            # Score balances visual prominence with vibrant color
            score = (count ** 0.45) * (s ** 0.85) * (v ** 0.40)
            scored.append((score, (r, g, b)))

        if scored:
            scored.sort(key=lambda x: x[0], reverse=True)
            chosen_rgb = scored[0][1]
        else:
            chosen_rgb = (122, 162, 247)

        # Boost saturation/brightness if needed for contrast
        h, s, v = colorsys.rgb_to_hsv(chosen_rgb[0]/255.0, chosen_rgb[1]/255.0, chosen_rgb[2]/255.0)
        if v < 0.60: v = 0.75
        if s < 0.40: s = 0.65
        ar, ag, ab = colorsys.hsv_to_rgb(h, s, v)
        return (int(ar * 255), int(ag * 255), int(ab * 255))
    except Exception as e:
        print(f"Error quantizing image: {e}")
        return (122, 162, 247)

def main():
    image_path = ""
    if len(sys.argv) > 1:
        image_path = os.path.expanduser(sys.argv[1])
    else:
        state_file = os.path.join(HOME, ".cache/current_wallpaper")
        if os.path.exists(state_file):
            with open(state_file, "r") as f:
                image_path = f.read().strip()

    manual_hex = get_manual_color()
    if manual_hex:
        accent_rgb = hex_to_rgb(manual_hex)
        accent_hex = manual_hex
    else:
        accent_rgb = extract_dominant_accent(image_path)
        accent_hex = f"#{accent_rgb[0]:02x}{accent_rgb[1]:02x}{accent_rgb[2]:02x}"

    wofi_op, waybar_op = get_glass_opacities()

    # Derived tinted glass background
    ar, ag, ab = accent_rgb
    bg_r = max(16, min(50, int(ar * 0.18 + 14 * 0.82)))
    bg_g = max(16, min(50, int(ag * 0.18 + 16 * 0.82)))
    bg_b = max(20, min(56, int(ab * 0.18 + 24 * 0.82)))

    accent_alpha = f"rgba({ar}, {ag}, {ab}, 0.20)"
    border_accent = f"rgba({ar}, {ag}, {ab}, 0.60)"
    bg_waybar = f"rgba({bg_r}, {bg_g}, {bg_b}, {waybar_op:.2f})"
    bg_wofi = f"rgba({bg_r}, {bg_g}, {bg_b}, {wofi_op:.2f})"

    # 1. Waybar colors.css
    waybar_css = f"""@define-color bg_color {bg_waybar};
@define-color accent_color {accent_hex};
@define-color accent_alpha {accent_alpha};
@define-color border_color {border_accent};
@define-color text_color #c0caf5;
@define-color text_muted #565f89;
"""
    os.makedirs(os.path.join(HOME, ".config/waybar"), exist_ok=True)
    with open(os.path.join(HOME, ".config/waybar/colors.css"), "w") as f:
        f.write(waybar_css)

    # 2. Wofi colors.css
    wofi_css = f"""@define-color bg_color {bg_wofi};
@define-color accent_color {accent_hex};
@define-color accent_alpha {accent_alpha};
@define-color border_color {border_accent};
@define-color text_color #e0e6fc;
@define-color text_muted #8a92b2;
"""
    os.makedirs(os.path.join(HOME, ".config/wofi"), exist_ok=True)
    with open(os.path.join(HOME, ".config/wofi/colors.css"), "w") as f:
        f.write(wofi_css)

    # 3. Dynamic Hyprland Active Window Border
    hypr_hex = f"0xee{accent_hex.lstrip('#')}"
    theme_lua = f"""-- cryo-hypr Dynamic Window Theme
hl.config({{
    general = {{
        col = {{
            active_border = {hypr_hex},
        }},
    }},
}})
"""
    with open(os.path.join(HOME, ".config/hypr/theme.lua"), "w") as f:
        f.write(theme_lua)

    # Apply live to Hyprland
    subprocess.run(["hyprctl", "eval", f'hl.config({{ general = {{ col = {{ active_border = {hypr_hex} }} }} }})'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print(f"Theme applied: Accent={accent_hex}, Glass={bg_waybar}")

if __name__ == "__main__":
    main()
