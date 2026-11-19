#!/usr/bin/env python3
"""Convert enemy scenes from static Sprite2D to animated Kenney SpriteFrames."""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Scene: (texture ext id, new scale or None, offset y or None, extra node transform kept)
# scale/offset chosen so each sprite fills its collision box and keeps feet at the
# old art ground line (canvas bottom stays at y=+64 in sprite-local space).
CONFIG = {
    "Walker": (2, 1.44, -28.1),
    "Enemy1": (1, None, None),
    "Enemy2": (1, 1.14, -8.7),
    "Enemy3": (1, 1.36, -23.3),
    "Enemy4": (1, 1.04, -2.2),
    "Enemy5": (1, 1.36, -23.3),
    "Enemy7": (1, 1.12, -7.8),
    "Enemy9": (1, 1.12, -7.8),
    "Enemy11": (1, 1.12, -7.8),
    "Enemy12": (1, 1.28, -18.1),
    "Fly1": (1, 1.66, None),
    "Fly2": (1, None, None),
    "Boss1": (1, 2.8, None),
    "Boss2": (3, 3.0, -76.5),
    "Boss3": (2, 1.77, -49.3),
}


def main():
    for scene, (ext_id, scale, offset_y) in CONFIG.items():
        path = os.path.join(ROOT, "Objects/Enemies", scene + ".tscn")
        name = scene.lower()
        with open(path) as f:
            text = f.read()
        if f"Kenney/{name}_frames.tres" in text:
            print("skip", scene)
            continue
        old = re.search(r'\[ext_resource path="[^"]*" type="Texture2D" id=%d\]' % ext_id, text)
        assert old, (scene, "texture ext_resource not found")
        text = text.replace(
            old.group(0),
            f'[ext_resource path="res://Assets/Sprites/Enemies/Kenney/{name}_frames.tres" type="SpriteFrames" id={ext_id}]',
        )
        # Convert only the first Sprite2D using this texture to AnimatedSprite2D.
        node_pat = re.compile(r'(\[node name="[^"]+" type=")Sprite2D(" parent="[^"]*"\]\n(?:[^\[]*?\n)?)texture = ExtResource\( %d \)\n' % ext_id)
        m = node_pat.search(text)
        assert m, (scene, "sprite node not found")
        props = f"frames = ExtResource( {ext_id} )\nautoplay = \"move\"\nanimation = \"move\"\n"
        if scale is not None:
            props += f"scale = Vector2( {scale}, {scale} )\n"
        if offset_y is not None:
            props += f"offset = Vector2( 0, {offset_y} )\n"
        replacement = f'{m.group(1)}AnimatedSprite2D{m.group(2)}{props}'
        text = text[:m.start()] + replacement + text[m.end():]
        with open(path, "w") as f:
            f.write(text)
        print("converted", scene)


if __name__ == "__main__":
    main()
