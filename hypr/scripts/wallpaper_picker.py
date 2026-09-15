#!/usr/bin/env python3
import os
import sys
import re
import time
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor
from PIL import Image

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, GtkLayerShell

Image.MAX_IMAGE_PIXELS = None

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
CACHE_DIR = os.path.expanduser("~/.cache/wallpaper_picker")
STATE_FILE = os.path.expanduser("~/.cache/current_wallpaper")
COLORS_FILE = os.path.expanduser("~/.config/wofi/colors.css")
os.makedirs(CACHE_DIR, exist_ok=True)

def read_dynamic_colors():
    accent_hex = "#7aa2f7"
    accent_alpha = "rgba(122, 162, 247, 0.25)"
    bg_color = "rgba(22, 24, 35, 0.85)"
    
    if os.path.exists(COLORS_FILE):
        try:
            with open(COLORS_FILE, "r") as f:
                content = f.read()
            m_acc = re.search(r"@define-color accent_color\s+([^;]+);", content)
            m_alp = re.search(r"@define-color accent_alpha\s+([^;]+);", content)
            m_bg = re.search(r"@define-color bg_color\s+([^;]+);", content)
            if m_acc: accent_hex = m_acc.group(1).strip()
            if m_alp: accent_alpha = m_alp.group(1).strip()
            if m_bg: bg_color = m_bg.group(1).strip()
        except Exception:
            pass
    return accent_hex, accent_alpha, bg_color

def format_title(filename):
    # Strip extension
    base = os.path.splitext(filename)[0]
    # If uuid-like
    if re.match(r"^[0-9a-fA-F-]{20,}$", base):
        return f"Wallpaper {base[:8]}"
    # Replace dashes and underscores with spaces
    cleaned = base.replace("-", " ").replace("_", " ")
    # Strip url prefixes like img1.wallspic.com
    cleaned = re.sub(r"^img\d+\.\w+\.\w+\s*", "", cleaned)
    # Strip desktop wallpaper tags
    cleaned = re.sub(r"4K vs 8K Desktop Wallpapers\s*", "Desktop Wall ", cleaned)
    # Capitalize words
    words = [w.capitalize() for w in cleaned.split() if w]
    title = " ".join(words)
    return title[:32] if len(title) > 32 else (title or filename)

def get_file_info(filepath):
    try:
        size_mb = os.path.getsize(filepath) / (1024 * 1024)
        ext = os.path.splitext(filepath)[1].lstrip(".").upper()
        with Image.open(filepath) as im:
            w, h = im.size
        return f"{w} × {h}  •  {size_mb:.1f} MB  •  {ext}"
    except Exception:
        return "Wallpaper Image"

class WallpaperPicker(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_title("Wallpaper Chooser")
        self.set_name("WallpaperPickerWindow")

        # Configure GtkLayerShell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_namespace(self, "wallpaper-picker")
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

        # Store initial wallpaper for cancel/revert
        self.initial_wallpaper = ""
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, "r") as f:
                    self.initial_wallpaper = f.read().strip()
            except Exception:
                pass

        self.current_selected_wall = self.initial_wallpaper
        self.confirmed = False
        self.debounce_timer = None

        # Gather wallpapers
        self.wallpapers = []
        if os.path.isdir(WALLPAPER_DIR):
            for f in sorted(os.listdir(WALLPAPER_DIR)):
                if f.lower().endswith(('.png', '.jpg', '.jpeg')):
                    self.wallpapers.append(os.path.join(WALLPAPER_DIR, f))

        self.setup_css()
        self.setup_ui()

        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", self.on_destroy)

        # Select initial wallpaper or first item
        GLib.idle_add(self.select_initial_item)

    def setup_css(self):
        accent_hex, accent_alpha, bg_color = read_dynamic_colors()
        css = f"""
        window {{
            background: transparent;
        }}
        #picker-card {{
            background-color: {bg_color};
            border: 1px solid rgba(255, 255, 255, 0.16);
            border-radius: 22px;
            box-shadow: 0 24px 64px rgba(0, 0, 0, 0.75), inset 0 1px 0 rgba(255, 255, 255, 0.22);
            padding: 16px;
        }}
        #search-entry {{
            background-color: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.14);
            border-radius: 12px;
            color: #ffffff;
            font-size: 13px;
            padding: 9px 14px;
        }}
        #search-entry:focus {{
            border: 1px solid {accent_hex};
            background-color: rgba(255, 255, 255, 0.12);
            box-shadow: 0 0 12px {accent_alpha};
        }}
        #wall-list {{
            background: transparent;
        }}
        #wall-list row {{
            background: transparent;
            border-radius: 12px;
            padding: 6px 8px;
            margin: 2px 4px;
            border: 1px solid transparent;
            transition: all 120ms ease;
        }}
        #wall-list row:hover {{
            background-color: rgba(255, 255, 255, 0.06);
        }}
        #wall-list row:selected {{
            background-color: {accent_alpha};
            border: 1px solid rgba(255, 255, 255, 0.22);
            box-shadow: 0 2px 8px {accent_alpha};
        }}
        #row-title {{
            color: #ffffff;
            font-size: 13px;
            font-weight: 600;
        }}
        #row-sub {{
            color: #8a92b2;
            font-size: 11px;
        }}
        #preview-box {{
            background-color: rgba(0, 0, 0, 0.35);
            border: 1px solid rgba(255, 255, 255, 0.14);
            border-radius: 16px;
            box-shadow: 0 12px 30px rgba(0, 0, 0, 0.50), inset 0 1px 0 rgba(255, 255, 255, 0.15);
            padding: 8px;
        }}
        #preview-title {{
            color: #ffffff;
            font-size: 17px;
            font-weight: 700;
        }}
        #preview-badge {{
            color: #c0caf5;
            font-size: 12px;
            background-color: rgba(255, 255, 255, 0.08);
            border-radius: 8px;
            padding: 4px 10px;
        }}
        #live-pill {{
            color: {accent_hex};
            font-size: 12px;
            font-weight: 600;
            background-color: {accent_alpha};
            border-radius: 8px;
            padding: 4px 10px;
        }}
        #apply-button {{
            background-color: {accent_hex};
            color: #12141d;
            font-size: 13px;
            font-weight: 700;
            border-radius: 10px;
            padding: 8px 18px;
            border: none;
            box-shadow: 0 4px 14px {accent_alpha};
        }}
        #apply-button:hover {{
            opacity: 0.92;
        }}
        #hint-label {{
            color: #7a829e;
            font-size: 11px;
        }}
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def setup_ui(self):
        # Outer Card
        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        card.set_name("picker-card")
        card.set_size_request(860, 520)
        self.add(card)

        # ------------------ LEFT PANEL (List & Search) ------------------
        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        left_box.set_size_request(320, -1)
        card.pack_start(left_box, False, False, 0)

        # Search Bar
        self.search_entry = Gtk.Entry()
        self.search_entry.set_name("search-entry")
        self.search_entry.set_placeholder_text("  Search wallpapers...")
        self.search_entry.connect("changed", self.on_search_changed)
        left_box.pack_start(self.search_entry, False, False, 0)

        # Scrolled List
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.NONE)
        left_box.pack_start(scrolled, True, True, 0)

        self.listbox = Gtk.ListBox()
        self.listbox.set_name("wall-list")
        self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.listbox.set_filter_func(self.filter_func)
        self.listbox.connect("row-selected", self.on_row_selected)
        self.listbox.connect("row-activated", self.on_row_activated)
        scrolled.add(self.listbox)

        # Populate rows
        self.row_widgets = []
        for wall_path in self.wallpapers:
            row = self.create_wallpaper_row(wall_path)
            self.listbox.add(row)
            self.row_widgets.append((wall_path, row))

        # Bottom Count Label
        self.count_label = Gtk.Label(label=f"🖼️ {len(self.wallpapers)} Wallpapers Available")
        self.count_label.set_name("hint-label")
        self.count_label.set_halign(Gtk.Align.START)
        left_box.pack_start(self.count_label, False, False, 0)

        # ------------------ RIGHT PANEL (Preview Card) ------------------
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        card.pack_start(right_box, True, True, 0)

        # Header Info Row
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        right_box.pack_start(header_box, False, False, 0)

        self.preview_title = Gtk.Label(label="Select a Wallpaper")
        self.preview_title.set_name("preview-title")
        self.preview_title.set_halign(Gtk.Align.START)
        header_box.pack_start(self.preview_title, True, True, 0)

        self.preview_badge = Gtk.Label(label="")
        self.preview_badge.set_name("preview-badge")
        header_box.pack_end(self.preview_badge, False, False, 0)

        # Preview Frame & Image
        self.preview_frame = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.preview_frame.set_name("preview-box")
        self.preview_frame.set_size_request(480, 275)
        self.preview_frame.set_valign(Gtk.Align.CENTER)
        self.preview_frame.set_halign(Gtk.Align.CENTER)
        right_box.pack_start(self.preview_frame, True, True, 0)

        self.preview_image = Gtk.Image()
        self.preview_frame.pack_start(self.preview_image, True, True, 0)

        # Bottom Controls Row
        bottom_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        right_box.pack_start(bottom_box, False, False, 0)

        live_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        live_pill = Gtk.Label(label="👁️  Live Desktop Preview")
        live_pill.set_name("live-pill")
        live_box.pack_start(live_pill, False, False, 0)

        hint = Gtk.Label(label="[↵] Apply   [Esc] Cancel   [↑↓] Switch")
        hint.set_name("hint-label")
        live_box.pack_start(hint, False, False, 0)
        bottom_box.pack_start(live_box, True, True, 0)

        apply_btn = Gtk.Button(label="Set Wallpaper  →")
        apply_btn.set_name("apply-button")
        apply_btn.connect("clicked", lambda b: self.confirm_and_apply())
        bottom_box.pack_end(apply_btn, False, False, 0)

    def create_wallpaper_row(self, wall_path):
        row = Gtk.ListBoxRow()
        row.wall_path = wall_path
        row.title_text = format_title(os.path.basename(wall_path))

        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.add(hbox)

        # Thumbnail
        thumb_img = Gtk.Image()
        thumb_path = os.path.join(CACHE_DIR, f"icon_{os.path.basename(wall_path)}.jpg")
        if os.path.exists(thumb_path):
            try:
                pb = GdkPixbuf.Pixbuf.new_from_file(thumb_path)
                thumb_img.set_from_pixbuf(pb)
            except Exception:
                pass
        hbox.pack_start(thumb_img, False, False, 0)

        # Labels
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        vbox.set_valign(Gtk.Align.CENTER)
        hbox.pack_start(vbox, True, True, 0)

        lbl_title = Gtk.Label(label=row.title_text)
        lbl_title.set_name("row-title")
        lbl_title.set_halign(Gtk.Align.START)
        vbox.pack_start(lbl_title, False, False, 0)

        lbl_sub = Gtk.Label(label=os.path.basename(wall_path))
        lbl_sub.set_name("row-sub")
        lbl_sub.set_halign(Gtk.Align.START)
        lbl_sub.set_ellipsize(3) # PANGO_ELLIPSIZE_END
        lbl_sub.set_max_width_chars(25)
        vbox.pack_start(lbl_sub, False, False, 0)

        return row

    def select_initial_item(self):
        target_row = None
        for wall_path, row in self.row_widgets:
            if wall_path == self.initial_wallpaper:
                target_row = row
                break
        if not target_row and self.row_widgets:
            target_row = self.row_widgets[0][1]

        if target_row:
            self.listbox.select_row(target_row)
            target_row.grab_focus()
        return False

    def filter_func(self, row):
        query = self.search_entry.get_text().lower().strip()
        if not query:
            return True
        name = os.path.basename(row.wall_path).lower()
        title = row.title_text.lower()
        return query in name or query in title

    def on_search_changed(self, entry):
        self.listbox.invalidate_filter()
        # Select first visible row
        for child in self.listbox.get_children():
            if child.get_child_visible():
                self.listbox.select_row(child)
                break

    def on_row_selected(self, listbox, row):
        if not row:
            return
        wall_path = row.wall_path
        self.current_selected_wall = wall_path

        # Update title & badge
        self.preview_title.set_text(row.title_text)
        self.preview_badge.set_text(get_file_info(wall_path))

        # Update Preview Image
        self.load_preview_image(wall_path)

        # Debounced live background preview
        if self.debounce_timer:
            GLib.source_remove(self.debounce_timer)
        self.debounce_timer = GLib.timeout_add(70, self.apply_live_preview, wall_path)

    def load_preview_image(self, wall_path):
        prev_path = os.path.join(CACHE_DIR, f"prev_{os.path.basename(wall_path)}.jpg")
        if os.path.exists(prev_path):
            try:
                pb = GdkPixbuf.Pixbuf.new_from_file(prev_path)
                self.preview_image.set_from_pixbuf(pb)
                return
            except Exception:
                pass

        # Fallback load
        try:
            pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(wall_path, 480, 270, True)
            self.preview_image.set_from_pixbuf(pb)
        except Exception as e:
            print("Error loading preview:", e)

    def apply_live_preview(self, wall_path):
        self.debounce_timer = None
        # Fast wallpaper switch on desktop without animation for instant response
        subprocess.Popen(["awww", "img", wall_path, "--transition-type", "none"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return False

    def on_row_activated(self, listbox, row):
        self.confirm_and_apply()

    def confirm_and_apply(self):
        self.confirmed = True
        wall = self.current_selected_wall
        if wall and os.path.isfile(wall):
            # Save state
            with open(STATE_FILE, "w") as f:
                f.write(wall)

            # Animated transition
            subprocess.Popen([
                "awww", "img", wall,
                "--transition-type", "wipe",
                "--transition-angle", "30",
                "--transition-step", "90"
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # Extract dynamic colors & reload bar
            extract_script = os.path.expanduser("~/.config/hypr/scripts/extract_colors.py")
            subprocess.Popen(["python3", extract_script, wall])

            # Notification
            name = os.path.basename(wall)
            subprocess.Popen(["notify-send", "Wallpaper Set", f"✨ {name}"])

            # Reload Waybar with new dynamic palette
            subprocess.Popen(["bash", "-c", "sleep 0.3; killall waybar 2>/dev/null; sleep 0.2; waybar &"])

        self.destroy()

    def cancel_and_revert(self):
        if not self.confirmed and self.initial_wallpaper and os.path.isfile(self.initial_wallpaper):
            subprocess.Popen(["awww", "img", self.initial_wallpaper, "--transition-type", "none"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.destroy()

    def on_key_press(self, widget, event):
        keyval = event.keyval
        # Escape
        if keyval == Gdk.KEY_Escape:
            self.cancel_and_revert()
            return True
        # Return / Enter
        elif keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            self.confirm_and_apply()
            return True
        # Up / Down arrows when focused on search entry should navigate list
        elif keyval in (Gdk.KEY_Up, Gdk.KEY_Down):
            selected = self.listbox.get_selected_row()
            idx = selected.get_index() if selected else 0
            visible_rows = [r for r in self.listbox.get_children() if r.get_child_visible()]
            if not visible_rows:
                return False
            
            try:
                curr_idx = visible_rows.index(selected)
            except ValueError:
                curr_idx = 0

            if keyval == Gdk.KEY_Up and curr_idx > 0:
                target = visible_rows[curr_idx - 1]
                self.listbox.select_row(target)
                target.grab_focus()
                return True
            elif keyval == Gdk.KEY_Down and curr_idx < len(visible_rows) - 1:
                target = visible_rows[curr_idx + 1]
                self.listbox.select_row(target)
                target.grab_focus()
                return True

        return False

    def on_destroy(self, widget):
        if not self.confirmed:
            self.cancel_and_revert()
        Gtk.main_quit()

def main():
    # Enforce single instance toggle
    win = WallpaperPicker()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
