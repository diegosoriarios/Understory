#!/usr/bin/env python3
"""Build the parallax backdrop textures from Kenney background art."""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Assets/Sprites/kenney_platformer-pack-remastered/PNG/Backgrounds")
OUT = os.path.join(ROOT, "Assets/Sprites/Assets")
W, H = 384, 224
SKY = (208, 244, 247)
THRESHOLD = 8


def scaled(name):
    return Image.open(os.path.join(SRC, name)).convert("RGBA").resize((W, W), Image.LANCZOS)


def strip_sky(img):
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a and abs(r - SKY[0]) + abs(g - SKY[1]) + abs(b - SKY[2]) <= THRESHOLD:
                px[x, y] = (r, g, b, 0)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    sky = scaled("colored_grass.png").crop((0, 0, W, H))
    sky.save(os.path.join(OUT, "kenney_sky.png"))
    for name, out in (("blue_land", "kenney_far"), ("blue_grass", "kenney_mid"), ("colored_grass", "kenney_near")):
        hill = strip_sky(scaled(name + ".png").crop((0, 100, W, 324)))
        hill.save(os.path.join(OUT, out + ".png"))
        print("wrote", out)


if __name__ == "__main__":
    main()
