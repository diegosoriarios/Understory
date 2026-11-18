#!/usr/bin/env python3
"""Builds the stone variant of the jungle tileset used by the boss arenas."""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Assets/Sprites/Tiles/JungleDirtTileSet.png"
OUT_PNG = ROOT / "Assets/Sprites/Tiles/StoneTileSet.png"
OUT_TRES = ROOT / "Assets/StoneTileSet.tres"


def recolor(img):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src = img.load()
    dst = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = src[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            s *= 0.32
            v = min(1.0, v * 0.95 + 0.04)
            nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
            dst[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    return out


def main():
    img = Image.open(SRC).convert("RGBA")
    recolor(img).save(OUT_PNG)
    tres = (ROOT / "Assets/JungleDirtTileSet.tres").read_text()
    tres = tres.replace(
        "res://Assets/Sprites/Tiles/JungleDirtTileSet.png",
        "res://Assets/Sprites/Tiles/StoneTileSet.png",
    )
    OUT_TRES.write_text(tres)
    print(f"wrote {OUT_PNG.relative_to(ROOT)} and {OUT_TRES.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
