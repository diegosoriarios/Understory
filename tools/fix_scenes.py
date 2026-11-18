#!/usr/bin/env python3
"""One-shot scene fixes for Godot 4:

1. Player.tscn: SpriteFrames animations -> G4 format (frames as
   { "duration": 1.0, "texture": ... } dicts).
2. Player.tscn / Explosion.tscn: legacy `anims/X = SubResource(n)` on
   AnimationPlayer -> G4 AnimationLibrary resource + `libraries` property.
3. World.tscn: Environment property renames (fog_sun_color -> fog_light_color,
   drop removed glow_bicubic_upscale).
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def fix_spriteframes(path: Path) -> None:
    text = path.read_text()

    def repl(m):
        frames = re.findall(r"SubResource\(\s*(\d+)\s*\)", m.group(1))
        inner = ", ".join(
            '{\n"duration": 1.0,\n"texture": SubResource( %s )\n}' % f for f in frames
        )
        return '"frames": [' + inner + "]"

    new_text, n = re.subn(r'"frames": \[( SubResource\([^)]*\)(?:, SubResource\([^)]*\))*) \]', repl, text)
    assert n == 3, f"{path}: expected 3 SpriteFrames animations, got {n}"
    path.write_text(new_text)
    print(f"{path.name}: SpriteFrames -> G4 frame dicts ({n} animations)")


def fix_animation_library(path: Path, anim: str, sub_id: str) -> None:
    text = path.read_text()
    old = f"anims/{anim} = SubResource( {sub_id} )"
    if old not in text:
        assert "AnimationLibrary" in text, f"{path}: neither legacy nor converted form found"
        print(f"{path.name}: anims/{anim} already converted, skipping")
        return

    lib_id = 100  # numeric ids coexist with the format=2 loader
    lib_block = (
        f'[sub_resource type="AnimationLibrary" id={lib_id}]\n'
        f'_data = {{\n&"{anim}": SubResource( {sub_id} )\n}}\n\n'
    )
    # Insert the library sub_resource right before the first [node] block.
    idx = text.index("[node ")
    text = text[:idx] + lib_block + text[idx:]

    replacement = (
        "libraries = {\n"
        f'&"": SubResource( {lib_id} )\n'
        "}"
    )
    text = text.replace(old, replacement)
    path.write_text(text)
    print(f"{path.name}: anims/{anim} -> AnimationLibrary")


def fix_environment(path: Path) -> None:
    text = path.read_text()
    text, n1 = re.subn(r"\bfog_sun_color\b", "fog_light_color", text)
    text, n2 = re.subn(r"^glow_bicubic_upscale = [^\n]*\n", "", text, flags=re.M)
    path.write_text(text)
    print(f"{path.name}: fog rename={n1}, glow_bicubic_upscale removed={n2}")


def main():
    fix_spriteframes(ROOT / "Objects/Player.tscn")
    fix_animation_library(ROOT / "Objects/Player.tscn", "Attack", "28")
    fix_animation_library(ROOT / "Objects/Explosion.tscn", "explosion", "1")
    fix_environment(ROOT / "World.tscn")


if __name__ == "__main__":
    main()
