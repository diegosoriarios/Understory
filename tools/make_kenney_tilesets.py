#!/usr/bin/env python3
"""Rebuild the two 32px tile atlases from Kenney ground art (in place)."""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REM = os.path.join(ROOT, "Assets/Sprites/kenney_platformer-pack-remastered/PNG/Ground")
OUT = os.path.join(ROOT, "Assets/Sprites/Tiles")
CELL = 32
COLS, ROWS = 7, 6

# atlas coord -> source file stem (same layout for both tilesets)
LAYOUT = {
    (0, 1): "Left",
    (1, 1): "Mid",
    (2, 1): "Right",
    (4, 5): "Center",
    (0, 3): "Half_left",
    (1, 3): "Half_mid",
    (2, 3): "Half_right",
    (3, 0): "Hill_left",
    (4, 0): "Center_round",
    (5, 0): "Hill_right",
    (0, 5): "Cliff_left",
    (1, 5): "Cliff_right",
    (2, 5): "Corner_left",
    (3, 5): "Corner_right",
    (5, 5): "",  # the full ground tile (grass.png / stone.png)
}


def build(biome):
    src_dir = os.path.join(REM, biome)
    atlas = Image.new("RGBA", (COLS * CELL, ROWS * CELL), (0, 0, 0, 0))
    for (cx, cy), suffix in LAYOUT.items():
        if (cx, cy) == (4, 0) and biome == "Stone":
            suffix = "Center_rounded"
        stem = biome.lower() + suffix
        path = os.path.join(src_dir, stem + ".png")
        if not os.path.exists(path):
            raise SystemExit(f"missing {path}")
        tile = Image.open(path).convert("RGBA").resize((CELL, CELL), Image.LANCZOS)
        atlas.paste(tile, (cx * CELL, cy * CELL))
    return atlas


def main():
    for biome, name in (("Grass", "JungleDirtTileSet"), ("Stone", "StoneTileSet")):
        atlas = build(biome)
        out = os.path.join(OUT, name + ".png")
        atlas.save(out)
        print("wrote", out, atlas.size)


if __name__ == "__main__":
    main()
