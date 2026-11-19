#!/usr/bin/env python3
"""Cuts clean background decor sprites out of Assets/Sprites/Assets/Assets.png.

The atlas packs the props against each other, so each crop is masked to drop
neighbouring props that share the rectangle. Output goes to
Assets/Sprites/Assets/decor/ as individual PNGs the level generator places.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Assets/Sprites/Assets/Assets.png"
OUT = ROOT / "Assets/Sprites/Assets/decor"


def cut(src, box, keep, dome_rows=0, dome_inset=0):
    """Return the kept pixels of box, cropped to their own bounds.

    dome_rows/dome_inset round off a flat sprite top into a pointed canopy.
    """
    crop = src.crop((box[0], box[1], box[0] + box[2], box[1] + box[3]))
    px = crop.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if not keep(box[0] + x, box[1] + y):
                px[x, y] = (0, 0, 0, 0)
    for y in range(min(dome_rows, crop.height)):
        solid = [x for x in range(crop.width) if px[x, y][3] > 16]
        if not solid:
            continue
        lo, hi = min(solid), max(solid)
        inset = int(dome_inset * (1.0 - y / dome_rows) ** 0.6)
        for x in range(crop.width):
            if x < lo + inset or x > hi - inset:
                px[x, y] = (0, 0, 0, 0)
    bbox = crop.getbbox()
    return crop.crop(bbox) if bbox else crop


def main():
    src = Image.open(SRC).convert("RGBA")
    OUT.mkdir(parents=True, exist_ok=True)
    props = {
        # big pine: crown above y=266, trunk only x=84..134 below it
        "tree": ((5, 195, 173, 190), lambda x, y: y < 266 or 84 <= x <= 134, 54, 80),
        # small pine to the right of the big one
        "pine": ((158, 238, 78, 160), lambda x, y: y >= 266 or x >= 180),
        "rock": ((4, 300, 66, 50), lambda x, y: True),
        "boulder": ((344, 22, 48, 52), lambda x, y: True),
        "hedge": ((196, 10, 56, 36), lambda x, y: True),
        "mossrock": ((296, 8, 56, 36), lambda x, y: True),
    }
    for name, spec in props.items():
        box, keep = spec[0], spec[1]
        extra = spec[2:]
        img = cut(src, box, keep, *extra)
        path = OUT / f"{name}.png"
        img.save(path)
        print(f"{path.relative_to(ROOT)}: {img.width}x{img.height}")


if __name__ == "__main__":
    main()
