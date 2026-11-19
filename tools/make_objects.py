#!/usr/bin/env python3
"""Draws the procedural pickup/door/portal sprites into Assets/Sprites/."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Assets/Sprites"

GOLD = (246, 198, 74, 255)
GOLD_DARK = (122, 78, 18, 255)
GOLD_LIGHT = (255, 236, 158, 255)
WOOD = (112, 70, 38, 255)
WOOD_DARK = (62, 36, 18, 255)
WOOD_LIGHT = (146, 96, 54, 255)
METAL = (150, 158, 168, 255)
METAL_DARK = (74, 80, 90, 255)


def key_png():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((4, 18, 32, 46), fill=GOLD_DARK)
    d.ellipse((8, 22, 28, 42), fill=GOLD)
    d.ellipse((15, 29, 21, 35), fill=(0, 0, 0, 0))
    d.rectangle((26, 28, 60, 36), fill=GOLD_DARK)
    d.rectangle((28, 30, 58, 34), fill=GOLD)
    d.rectangle((48, 36, 54, 48), fill=GOLD_DARK)
    d.rectangle((49, 36, 52, 45), fill=GOLD)
    d.rectangle((57, 36, 61, 44), fill=GOLD_DARK)
    d.rectangle((57, 36, 59, 41), fill=GOLD)
    d.ellipse((11, 24, 17, 30), fill=GOLD_LIGHT)
    d.rectangle((30, 30, 46, 31), fill=GOLD_LIGHT)
    img.save(OUT / "key.png")


def door_png():
    img = Image.new("RGBA", (96, 120), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 95, 119), fill=WOOD_DARK)
    d.rectangle((4, 4, 91, 119), fill=WOOD)
    for x in range(4, 92, 18):
        d.rectangle((x, 6, x + 1, 117), fill=WOOD_DARK)
        d.rectangle((x + 3, 8, x + 4, 115), fill=WOOD_LIGHT)
    for y in (22, 92):
        d.rectangle((2, y, 93, y + 12), fill=METAL_DARK)
        d.rectangle((3, y + 2, 92, y + 9), fill=(96, 102, 112, 255))
        d.rectangle((3, y + 2, 92, y + 3), fill=METAL)
        for x in range(10, 90, 16):
            d.rectangle((x, y + 4, x + 3, y + 7), fill=(52, 56, 64, 255))
    d.ellipse((70, 50, 86, 66), fill=GOLD_DARK)
    d.ellipse((73, 53, 83, 63), fill=GOLD)
    d.ellipse((75, 55, 78, 58), fill=GOLD_LIGHT)
    img.save(OUT / "door.png")


def portal_png():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((4, 4, 123, 123), fill=(60, 200, 230, 26))
    d.ellipse((14, 14, 113, 113), fill=(90, 120, 230, 40))
    d.ellipse((22, 22, 105, 105), fill=(96, 64, 196, 170))
    d.ellipse((28, 28, 99, 99), fill=(42, 28, 120, 255))
    for i, (r, col) in enumerate([
        (30, (58, 44, 150, 255)),
        (23, (78, 84, 214, 255)),
        (16, (120, 190, 246, 255)),
        (9, (208, 246, 255, 255)),
    ]):
        d.ellipse((64 - r, 64 - r, 64 + r, 64 + r), fill=col)
    import math
    for arm in (0.0, math.pi):
        for t in range(120):
            ang = arm + t * 0.055
            rad = 5 + t * 0.20
            x = 64 + rad * math.cos(ang)
            y = 64 + rad * math.sin(ang)
            a = int(210 - t * 1.2)
            d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=(214, 248, 255, max(30, a)))
    for (x, y, r) in [(20, 44, 3), (104, 36, 2), (96, 96, 3), (30, 92, 2)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=(220, 250, 255, 255))
    img.save(OUT / "portal.png")


def spikes_png():
    img = Image.new("RGBA", (32, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 9, 31, 11), fill=METAL_DARK)
    d.rectangle((0, 9, 31, 9), fill=(104, 110, 120, 255))
    for cx in (6, 16, 26):
        d.polygon([(cx - 6, 10), (cx, 1), (cx + 6, 10)], fill=METAL_DARK)
        d.polygon([(cx - 4, 10), (cx, 3), (cx + 4, 10)], fill=(168, 176, 186, 255))
        d.line([(cx - 1, 9), (cx, 3)], fill=(226, 232, 240, 255))
    img.save(OUT / "spikes.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    key_png()
    door_png()
    portal_png()
    spikes_png()
    print("wrote key.png, door.png, portal.png, spikes.png")


if __name__ == "__main__":
    main()
