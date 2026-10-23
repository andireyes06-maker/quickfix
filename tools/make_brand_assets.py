"""Builds the app icons and the in-app logo mark from assets/brand/quickfix-logo.png.

Run from the project root: python3 -I tools/make_brand_assets.py
Needs Pillow. The source logo is a pin with a wrench above the word "QuickFix";
only the pin is used for icons, because the word is unreadable at icon size.
"""
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/brand/quickfix-logo.png"
BLUE = (29, 63, 152)  # the logo's own blue
WORD_TOP = 1300  # rows below this belong to the "QuickFix" word

logo = Image.open(SRC).convert("RGB")

# Find the pin: everything above the word that differs from the background.
above = logo.crop((0, 0, logo.width, WORD_TOP))
diff = ImageChops.difference(above, Image.new("RGB", above.size, BLUE)).convert("L")
pin_box = diff.point(lambda v: 255 if v > 20 else 0).getbbox()
px0, py0, px1, py1 = pin_box
pin_h = py1 - py0
cx = (px0 + px1) // 2
print("pin box", pin_box)

# A wide crop around the pin that stays above the word (padding is plain background).
crop_top = py0 - 60
crop_bottom = min(WORD_TOP - 5, py1 + 40)
pin_crop = logo.crop((cx - 450, crop_top, cx + 450, crop_bottom))
pin_center_in_crop = ((py0 + py1) // 2 - crop_top)


def render(size, pin_fraction, transparent=False):
    """Square canvas of the logo blue with the pin centred, pin_fraction of the height."""
    scale = size * pin_fraction / pin_h
    w, h = round(pin_crop.width * scale), round(pin_crop.height * scale)
    scaled = pin_crop.resize((w, h), Image.LANCZOS)
    canvas = Image.new("RGB", (size, size), BLUE)
    canvas.paste(scaled, ((size - w) // 2, size // 2 - round(pin_center_in_crop * scale)))
    return canvas


def save(img, rel):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)


# Android legacy launcher icons (used below API 26 and as the adaptive fallback).
for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    save(render(px, 0.68), f"android/app/src/main/res/mipmap-{folder}/ic_launcher.png")

# Android adaptive icon foreground: 108dp canvas, pin kept inside the 66dp safe zone.
for folder, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
    save(render(px, 0.52), f"android/app/src/main/res/mipmap-{folder}/ic_launcher_foreground.png")

# Web icons.
save(render(192, 0.68), "web/icons/Icon-192.png")
save(render(512, 0.68), "web/icons/Icon-512.png")
save(render(192, 0.52), "web/icons/Icon-maskable-192.png")
save(render(512, 0.52), "web/icons/Icon-maskable-512.png")
save(render(48, 0.80), "web/favicon.png")

# In-app logo mark (login screen and app bar).
save(render(256, 0.74), "assets/brand/quickfix-mark.png")
