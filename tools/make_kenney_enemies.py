#!/usr/bin/env python3
"""Copy Kenney enemy art into the project and build SpriteFrames resources."""
import os
import shutil
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REM = os.path.join(ROOT, "Assets/Sprites/kenney_platformer-pack-remastered/PNG/Enemies")
EXT = os.path.join(ROOT, "Assets/Sprites/kenney_platformer-art-extended-enemies/Enemy sprites")
OUT = os.path.join(ROOT, "Assets/Sprites/Enemies/Kenney")

# name: (pack dir, frame A, frame B, animation speed)
ENEMIES = {
    "walker": (REM, "slimeBlue.png", "slimeBlue_move.png", 5.0),
    "enemy1": (REM, "barnacle.png", "barnacle_attack.png", 5.0),
    "enemy2": (REM, "snail.png", "snail_move.png", 4.0),
    "enemy3": (REM, "slimeGreen.png", "slimeGreen_move.png", 5.0),
    "enemy4": (REM, "saw.png", "saw_move.png", 8.0),
    "enemy5": (REM, "slimePurple.png", "slimePurple_move.png", 5.0),
    "enemy7": (REM, "frog.png", "frog_move.png", 5.0),
    "enemy9": (REM, "ladybug.png", "ladybug_move.png", 5.0),
    "enemy11": (REM, "mouse.png", "mouse_move.png", 6.0),
    "enemy12": (REM, "slimeBlock.png", "slimeBlock_move.png", 5.0),
    "fly1": (EXT, "bat.png", "bat_fly.png", 8.0),
    "fly2": (REM, "bee.png", "bee_move.png", 12.0),
    "boss1": (REM, "saw.png", "saw_move.png", 8.0),
    "boss2": (REM, "slimePurple.png", "slimePurple_move.png", 4.0),
    "boss3": (REM, "slimeGreen.png", "slimeGreen_move.png", 4.0),
}


def copy_frame(src, dst, canvas=None):
    img = Image.open(src).convert("RGBA")
    if canvas is None:
        canvas_size = img.size
    else:
        canvas_size = canvas
    out = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    pos = ((canvas_size[0] - img.width) // 2, (canvas_size[1] - img.height) // 2)
    out.paste(img, pos, img)
    out.save(dst)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (src_dir, frame_a, frame_b, speed) in ENEMIES.items():
        canvas = (96, 48) if name == "fly1" else None
        a = os.path.join(OUT, f"{name}_a.png")
        b = os.path.join(OUT, f"{name}_b.png")
        copy_frame(os.path.join(src_dir, frame_a), a, canvas)
        copy_frame(os.path.join(src_dir, frame_b), b, canvas)
        tres = f'''[gd_resource type="SpriteFrames" load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://Assets/Sprites/Enemies/Kenney/{name}_a.png" id="1"]
[ext_resource type="Texture2D" path="res://Assets/Sprites/Enemies/Kenney/{name}_b.png" id="2"]

[resource]
animations = [{{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("1")
}}, {{
"duration": 1.0,
"texture": ExtResource("2")
}}],
"loop": true,
"name": &"move",
"speed": {speed:.1f}
}}]
'''
        with open(os.path.join(OUT, f"{name}_frames.tres"), "w") as f:
            f.write(tres)
        print(f"wrote {name}")


if __name__ == "__main__":
    main()
