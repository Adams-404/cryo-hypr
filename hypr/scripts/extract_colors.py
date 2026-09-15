#!/usr/bin/env python3
import sys
import os
import colorsys
from PIL import Image

def get_palette(image_path):
    if not os.path.isfile(image_path):
        return None

    try:
        img = Image.open(image_path).convert("RGB")
        img = img.resize((120, 120))
        colors = img.getcolors(maxcolors=20000)
    except Exception as e:
        print(f"Error loading image: {e}")
        return None

    if not colors:
        return None

    # Collect colors with HSV
    color_data = []
    for count, (r, g, b) in colors:
        h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        color_data.append({
            "count": count,
            "rgb": (r, g, b),
            "h": h, "s": s, "v": v,
            "score": s * v
        })

    # Sort by vibrancy (saturation * brightness)
    vibrant = sorted(color_data, key=lambda x: (x["score"], x["count"]), reverse=True)
    accent_rgb = vibrant[0]["rgb"] if vibrant else (122, 162, 247)

    # Ensure accent is visible (boost brightness if too dark)
    h, s, v = colorsys.rgb_to_hsv(accent_rgb[0]/255.0, accent_rgb[1]/255.0, accent_rgb[2]/255.0)
    if v < 0.55:
        v = 0.75
    if s < 0.35:
        s = 0.65
    ar, ag, ab = colorsys.hsv_to_rgb(h, s, v)
    accent_rgb = (int(ar * 255), int(ag * 255), int(ab * 255))

    # Base dark tone derived from wallpaper
    dark_tones = [c for c in color_data if c["v"] < 0.3]
    if dark_tones:
        dark_tones.sort(key=lambda x: x["count"], reverse=True)
        dr, dg, db = dark_tones[0]["rgb"]
        # Blend slightly with dark slate for readability
        bg_r = max(14, min(36, int(dr * 0.4 + 16 * 0.6)))
        bg_g = max(16, min(40, int(dg * 0.4 + 18 * 0.6)))
        bg_b = max(24, min(52, int(db * 0.4 + 28 * 0.6)))
    else:
        bg_r, bg_g, bg_b = 20, 22, 32

    accent_hex = f"#{accent_rgb[0]:02x}{accent_rgb[1]:02x}{accent_rgb[2]:02x}"
    accent_alpha = f"rgba({accent_rgb[0]}, {accent_rgb[1]}, {accent_rgb[2]}, 0.16)"
    border_accent = f"rgba({accent_rgb[0]}, {accent_rgb[1]}, {accent_rgb[2]}, 0.55)"
    bg_waybar = f"rgba({bg_r}, {bg_g}, {bg_b}, 0.82)"
    bg_wofi = f"rgba({bg_r}, {bg_g}, {bg_b}, 0.72)"

    return {
        "accent_hex": accent_hex,
        "accent_alpha": accent_alpha,
        "border_accent": border_accent,
        "bg_waybar": bg_waybar,
        "bg_wofi": bg_wofi,
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_colors.py <image_path>")
        sys.exit(1)

    image_path = os.path.expanduser(sys.argv[1])
    palette = get_palette(image_path)
    if not palette:
        palette = {
            "accent_hex": "#7aa2f7",
            "accent_alpha": "rgba(122, 162, 247, 0.16)",
            "border_accent": "rgba(122, 162, 247, 0.55)",
            "bg_waybar": "rgba(22, 24, 35, 0.82)",
            "bg_wofi": "rgba(22, 24, 35, 0.72)",
        }

    home = os.path.expanduser("~")
    
    # 1. Waybar colors.css
    waybar_css = f"""@define-color bg_color {palette['bg_waybar']};
@define-color accent_color {palette['accent_hex']};
@define-color accent_alpha {palette['accent_alpha']};
@define-color border_color {palette['border_accent']};
@define-color text_color #c0caf5;
@define-color text_muted #565f89;
"""
    os.makedirs(os.path.join(home, ".config/waybar"), exist_ok=True)
    with open(os.path.join(home, ".config/waybar/colors.css"), "w") as f:
        f.write(waybar_css)

    # 2. Wofi colors.css
    wofi_css = f"""@define-color bg_color {palette['bg_wofi']};
@define-color accent_color {palette['accent_hex']};
@define-color accent_alpha {palette['accent_alpha']};
@define-color border_color {palette['border_accent']};
@define-color text_color #e0e6fc;
@define-color text_muted #8a92b2;
"""
    os.makedirs(os.path.join(home, ".config/wofi"), exist_ok=True)
    with open(os.path.join(home, ".config/wofi/colors.css"), "w") as f:
        f.write(wofi_css)

    print(f"Palette generated: Accent={palette['accent_hex']}, Bg={palette['bg_waybar']}")

if __name__ == "__main__":
    main()
