#!/usr/bin/env python3
"""Rebuild level decor at the original sizes using Kenney art."""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILES = os.path.join(ROOT, "Assets/Sprites/kenney_platformer-pack-remastered/PNG/Tiles")
OUT = os.path.join(ROOT, "Assets/Sprites/Assets/decor")

WOOD = (197, 143, 92, 255)
WOOD_LIGHT = (207, 166, 124, 255)
GREEN = (122, 183, 30, 255)


def content(img):
    box = img.getbbox()
    return img.crop(box)


def bush():
    return content(Image.open(os.path.join(TILES, "bush.png")).convert("RGBA"))


def rock():
    return content(Image.open(os.path.join(TILES, "rock.png")).convert("RGBA"))


def fit(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def tree():
    canvas = Image.new("RGBA", (117, 184), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((52, 86, 66, 182), radius=7, fill=WOOD)
    draw.rounded_rectangle((52, 86, 57, 182), radius=5, fill=WOOD_LIGHT)
    draw.ellipse((44, 172, 74, 184), fill=WOOD)
    b = bush()
    canvas.alpha_composite(fit(b, 117, 74), (0, 0))
    canvas.alpha_composite(fit(b, 88, 56), (10, 38))
    canvas.alpha_composite(fit(b, 62, 40), (44, 4))
    return canvas


def pine():
    canvas = Image.new("RGBA", (72, 145), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((33, 84, 41, 143), radius=4, fill=WOOD)
    b = bush()
    canvas.alpha_composite(fit(b, 72, 50), (0, 0))
    canvas.alpha_composite(fit(b, 58, 44), (7, 28))
    canvas.alpha_composite(fit(b, 44, 38), (14, 58))
    return canvas


def rock_decor(w, h):
    return fit(rock(), w, h)


def hedge():
    return fit(bush(), 44, 17)


def mossrock():
    canvas = Image.new("RGBA", (40, 31), (0, 0, 0, 0))
    canvas.alpha_composite(fit(rock(), 40, 26), (0, 5))
    canvas.alpha_composite(fit(bush(), 34, 14), (3, 0))
    return canvas


def main():
    os.makedirs(OUT, exist_ok=True)
    images = {
        "tree": tree(),
        "pine": pine(),
        "rock": rock_decor(60, 50),
        "boulder": rock_decor(32, 26),
        "hedge": hedge(),
        "mossrock": mossrock(),
    }
    for name, img in images.items():
        img.save(os.path.join(OUT, name + ".png"))
        print("wrote", name, img.size)


if __name__ == "__main__":
    main()
