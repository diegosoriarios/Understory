#!/usr/bin/env python3
"""Generates the campaign levels from ASCII terrain maps + entity placements.

Terrain legend (rows of equal width):
  '.' air        '#' ground (auto top-cap/fill)      '=' floating platform
  'L' lava (one 32x32 Lava instance per cell, no tile)

Entity placements are (symbol, col, row) lists; symbols:
  M start  N portal  W Walker  F Fly1  G Fly2  1-5/7/9 EnemyN  E Enemy11
  T Enemy12  S spawner  H moving platform  ^ spikes  K key  D door  B boss

Writes the .tscn files and /tmp/opencode/levels_manifest.json for verification.
"""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_MANIFEST = Path("/tmp/opencode/levels_manifest.json")
TILE = 32

SCENES = {
    "player": "res://Objects/Player.tscn",
    "tileset": "res://Assets/JungleDirtTileSet.tres",
    "stone_tileset": "res://Assets/StoneTileSet.tres",
    "portal": "res://Objects/NextLevel.tscn",
    "spawner": "res://Objects/Spwaner.tscn",
    "key": "res://Objects/Chave.tscn",
    "door": "res://Objects/Door.tscn",
    "lava": "res://Objects/Lava.tscn",
    "spikes": "res://Objects/Spikes.tscn",
    "mover": "res://EnemyH.tscn",
    "doublejump": "res://Objects/DoubleJumpPickup.tscn",
    "walljump": "res://Objects/WallJumpPickup.tscn",
    "backdrop": "res://Objects/Backdrop.tscn",
    "W": "res://Objects/Enemies/Walker.tscn",
    "F": "res://Objects/Enemies/Fly1.tscn",
    "G": "res://Objects/Enemies/Fly2.tscn",
    "1": "res://Objects/Enemies/Enemy1.tscn",
    "2": "res://Objects/Enemies/Enemy2.tscn",
    "3": "res://Objects/Enemies/Enemy3.tscn",
    "4": "res://Objects/Enemies/Enemy4.tscn",
    "5": "res://Objects/Enemies/Enemy5.tscn",
    "7": "res://Objects/Enemies/Enemy7.tscn",
    "9": "res://Objects/Enemies/Enemy9.tscn",
    "E": "res://Objects/Enemies/Enemy11.tscn",
    "T": "res://Objects/Enemies/Enemy12.tscn",
    "B1": "res://Objects/Enemies/Boss1.tscn",
    "B2": "res://Objects/Enemies/Boss2.tscn",
    "B3": "res://Objects/Enemies/Boss3.tscn",
}

# entity symbol -> ext-resource key (identity unless listed)
SYM_TO_KEY = {
    "^": "spikes", "N": "portal", "S": "spawner", "K": "key", "D": "door", "H": "mover",
    "A": "doublejump", "J": "walljump",
}

# tile id -> atlas coords in JungleDirtTileSet
TILE_CAP, TILE_FILL, TILE_PLAT = 4, 9, 1
# grass-topped ground cap: left end, middle, right end
CAP_ATLAS = [(0, 1), (1, 1), (2, 1)]
ATLAS = {TILE_FILL: (4, 5), TILE_PLAT: (1, 3)}

# background props: texture, z_index, optional atmospheric tint
DECOR = {
    "tree": ("res://Assets/Sprites/Assets/decor/tree.png", -2, (0.88, 0.95, 0.88)),
    "pine": ("res://Assets/Sprites/Assets/decor/pine.png", -1, (0.94, 1.0, 0.94)),
    "rock": ("res://Assets/Sprites/Assets/decor/rock.png", -1, None),
    "boulder": ("res://Assets/Sprites/Assets/decor/boulder.png", -1, None),
    "hedge": ("res://Assets/Sprites/Assets/decor/hedge.png", -1, None),
    "mossrock": ("res://Assets/Sprites/Assets/decor/mossrock.png", -1, None),
}


def png_size(res_path):
    with open(ROOT / res_path[len("res://"):], "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])

NAME_BY_SYMBOL = {
    "W": "Walker", "F": "Fly1", "G": "Fly2", "1": "Enemy1", "2": "Enemy2",
    "3": "Enemy3", "4": "Enemy4", "5": "Enemy5", "7": "Enemy7", "9": "Enemy9",
    "E": "Enemy11", "T": "Enemy12", "S": "Spawner", "H": "Platform",
    "^": "Spikes", "K": "Key", "D": "Door", "N": "Portal", "B": "Boss",
    "A": "DoubleJumpPickup", "J": "WallJumpPickup",
}

LEVELS = [
    {
        # ---------------- 1. TUTORIAL ----------------
        "path": "World.tscn",
        "target": "res://Levels/1.tscn",
        "terrain": [
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 17 + "===" + "." * 36,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "#" * 12 + "LLLL" + "#" * 20 + "LLLL" + "#" * 16,
            "#" * 56,
        ],
        "entities": [
            ("M", 2, 11),
            ("W", 8, 11),
            ("F", 6, 10),
            ("W", 24, 11),
            ("F", 32, 10),
            ("S", 34, 11),
            ("W", 42, 11),
            ("N", 53, 11),
        ],
        "decor": [
            ("tree", 20, False),
            ("pine", 44, True),
            ("rock", 6, False),
            ("hedge", 32, False),
            ("boulder", 50, False),
            ("mossrock", 26, False),
        ],
        "spawners": [(["W"], 1)],
        "boss": None,
    },
    {
        # ---------------- 2. COMBAT GAUNTLET ----------------
        "path": "Levels/1.tscn",
        "target": "res://Levels/2.tscn",
        "terrain": [
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 24 + "####" + "." * 36,
            "." * 64,
            "." * 14 + "######" + "." * 20 + "########" + "." * 11 + "#####",
            "." * 14 + "######" + "." * 20 + "########" + "." * 11 + "#####",
            "." * 14 + "######" + "." * 20 + "########" + "." * 11 + "#####",
            "." * 14 + "######" + "." * 20 + "########" + "." * 16,
            "." * 14 + "######" + "." * 20 + "########" + "." * 16,
            "#" * 30 + "LLLL" + "#" * 30,
            "#" * 64,
        ],
        "entities": [
            ("M", 2, 13),
            ("W", 10, 13),
            ("1", 17, 8),
            ("W", 26, 13),
            ("S", 28, 13),
            ("3", 36, 13),
            ("2", 44, 8),
            ("K", 47, 8),
            ("1", 50, 13),
            ("^", 55, 13),
            ("^", 56, 13),
            ("^", 57, 13),
            ("D", 61, 13),
            ("N", 62, 13),
        ],
        "decor": [
            ("tree", 8, False),
            ("tree", 34, True),
            ("pine", 22, True),
            ("rock", 47, False),
            ("hedge", 12, False),
            ("mossrock", 28, False),
            ("boulder", 58, False),
        ],
        "spawners": [(["1", "3"], 2)],
        "boss": None,
    },
    {
        # ---------------- 3. PLATFORMING ----------------
        "path": "Levels/2.tscn",
        "target": "res://Levels/3.tscn",
        "terrain": [
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 64,
            "." * 9 + "#" + "." * 4 + "#" + "." * 35 + "===" + "." * 11,
            "." * 9 + "#" + "." * 4 + "#" + "." * 49,
            "." * 9 + "#" + "." * 4 + "#" + "." * 36 + "===" + "." * 10,
            "." * 9 + "#" + "." * 4 + "#" + "." * 49,
            "." * 9 + "#" + "." * 4 + "#" + "." * 49,
            "." * 9 + "#" + "." * 4 + "#" + "." * 33 + "===" + "." * 7 + "#####.",
            "." * 9 + "#" + "." * 4 + "#" + "." * 5 + "===" + "." * 4 + "===" + "." * 8 + "===" + "." * 17 + "#####" + ".",
            "." * 9 + "#" + "." * 4 + "#" + "." * 49,
            "." * 9 + "#" + "." * 4 + "#" + "." * 49,
            "." * 14 + "#" + "." * 49,
            "#" * 18 + "L" * 28 + "#" * 18,
            "#" * 64,
        ],
        "entities": [
            ("M", 2, 15),
            ("J", 4, 15),
            ("W", 7, 15),
            ("A", 16, 15),
            ("S", 26, 8),
            ("H", 34, 14),
            ("F", 30, 11),
            ("G", 40, 10),
            ("K", 51, 5),
            ("D", 59, 15),
            ("N", 61, 15),
        ],
        "decor": [
            ("tree", 2, False),
            ("pine", 6, True),
            ("mossrock", 12, False),
            ("rock", 48, False),
            ("boulder", 52, False),
            ("tree", 60, True),
        ],
        "spawners": [(["F", "G"], 2)],
        "boss": None,
    },
    {
        # ---------------- 4. BOSS 1 ARENA ----------------
        "path": "Levels/3.tscn",
        "target": "res://Levels/4.tscn",
        "terrain": [
            "." * 48,
            "." * 48,
            "." * 48,
            "." * 48,
            "." * 48,
            "." * 48,
            "." * 48,
            "." * 48,
            "." * 42 + "#####" + ".",
            "." * 42 + "#####" + ".",
            "." * 48,
            "." * 48,
            "#" * 48,
            "#" * 48,
        ],
        "entities": [
            ("M", 2, 11),
            ("W", 8, 11),
            ("W", 12, 11),
            ("^", 16, 11),
            ("^", 17, 11),
            ("F", 20, 9),
            ("B", 30, 11),
            ("D", 44, 11),
            ("N", 46, 11),
        ],
        "decor": [
            ("rock", 8, False),
            ("boulder", 20, False),
            ("mossrock", 32, False),
            ("rock", 42, True),
        ],
        "spawners": [],
        "boss": "B1",
        "stone": True,
    },
    {
        # ---------------- 5. BOSS 2 ARENA ----------------
        "path": "Levels/4.tscn",
        "target": "res://Levels/5.tscn",
        "terrain": [
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 10 + "===" + "." * 17 + "===" + "." * 13 + "===" + "." + "#####" + ".",
            "." * 50 + "#####" + ".",
            "." * 56,
            "." * 56,
            "." * 56,
            "#" * 56,
            "#" * 56,
        ],
        "entities": [
            ("M", 2, 13),
            ("4", 14, 9),
            ("7", 20, 13),
            ("^", 24, 13),
            ("^", 25, 13),
            ("B", 38, 13),
            ("D", 52, 13),
            ("N", 54, 13),
        ],
        "decor": [
            ("rock", 6, False),
            ("boulder", 24, True),
            ("mossrock", 36, False),
            ("rock", 48, False),
        ],
        "spawners": [],
        "boss": "B2",
        "stone": True,
    },
    {
        # ---------------- 6. BOSS 3 FINALE ----------------
        "path": "Levels/5.tscn",
        "target": "res://Win.tscn",
        "terrain": [
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 56,
            "." * 40 + "===" + "." * 13,
            "." * 56,
            "." * 56,
            "." * 6 + "===" + "." * 25 + "===" + "." * 9 + "===" + "." + "#####" + ".",
            "." * 50 + "#####" + ".",
            "." * 56,
            "." * 56,
            "." * 56,
            "#" * 13 + "LLL" + "#" * 40,
            "#" * 56,
        ],
        "entities": [
            ("M", 2, 15),
            ("5", 8, 15),
            ("9", 14, 15),
            ("S", 20, 15),
            ("B", 40, 15),
            ("D", 52, 15),
            ("N", 54, 15),
        ],
        "decor": [
            ("rock", 6, False),
            ("boulder", 22, True),
            ("mossrock", 34, False),
            ("rock", 46, False),
        ],
        "spawners": [(["5", "9"], 2)],
        "boss": "B3",
        "stone": True,
    },
]


def cell_center(col, row):
    return (int((col + 0.5) * TILE), int((row + 0.5) * TILE))


def encode_cells(cells):
    data = struct.pack("<H", 0)
    for x, y, ax, ay in cells:
        data += struct.pack("<hhhhhh", x, y, 0, ax, ay, 0)
    return data


def build_level(spec):
    rows = spec["terrain"]
    width = len(rows[0])
    height = len(rows)
    assert all(len(r) == width for r in rows), f"{spec['path']}: ragged rows {[len(r) for r in rows]}"

    cells = []
    lava_cells = []
    for r, line in enumerate(rows):
        for c, ch in enumerate(line):
            if ch == "#":
                above = rows[r - 1][c] if r > 0 else "."
                if above in ".L":
                    left = rows[r][c - 1] if c > 0 else "."
                    right = rows[r][c + 1] if c + 1 < width else "."
                    if right != "#":
                        ax, ay = CAP_ATLAS[2]
                    elif left != "#":
                        ax, ay = CAP_ATLAS[0]
                    else:
                        ax, ay = CAP_ATLAS[1]
                else:
                    ax, ay = ATLAS[TILE_FILL]
                cells.append((c, r, ax, ay))
            elif ch == "=":
                ax, ay = ATLAS[TILE_PLAT]
                cells.append((c, r, ax, ay))
            elif ch == "L":
                lava_cells.append((c, r))

    # --- ext resources ---
    tileset_key = "stone_tileset" if spec.get("stone") else "tileset"
    used_keys = ["player", "tileset", "portal", "spawner", "key", "door", "backdrop"]
    if spec.get("stone"):
        used_keys.append("stone_tileset")
    ent_syms = {s for s, _, _ in spec["entities"] if s not in "MB"}
    for s in ent_syms:
        used_keys.append(SYM_TO_KEY.get(s, s))
    for pool, _ in spec["spawners"]:
        used_keys.extend(pool)
    if lava_cells:
        used_keys.append("lava")
    if spec["boss"]:
        used_keys.append(spec["boss"])
    for kind, _, _ in spec.get("decor", []):
        used_keys.append("decor_" + kind)
    # dedupe preserving order
    seen = set()
    ext = []
    for key in used_keys:
        if key in seen:
            continue
        seen.add(key)
        if key.startswith("decor_"):
            ext.append((key, DECOR[key[len("decor_"):]][0], "Texture2D"))
        else:
            is_tileset = key in ("tileset", "stone_tileset")
            ext.append((key, SCENES[key], "TileSet" if is_tileset else "PackedScene"))
    ext_ids = {key: i + 1 for i, (key, _, _) in enumerate(ext)}
    ext_lines = [
        f'[ext_resource path="{path}" type="{res_type}" id={ext_ids[key]}]'
        for key, path, res_type in ext
    ]

    nodes = []
    counters = {}

    def name_for(sym):
        base = NAME_BY_SYMBOL.get(sym, sym)
        counters[base] = counters.get(base, 0) + 1
        return f"{base}{counters[base]}" if counters[base] > 1 or sym in "S^" else base

    spawner_cfgs = list(spec["spawners"])
    spawner_i = 0

    for sym, col, row in spec["entities"]:
        px, py = cell_center(col, row)
        assert rows[row][col] == ".", f"{spec['path']}: entity {sym} at ({col},{row}) not in air"
        if sym == "M":
            continue  # handled by initPos + Player below
        node_name = name_for(sym)
        if sym == "N":
            nodes.append(
                f'[node name="{node_name}" parent="." instance=ExtResource( {ext_ids["portal"]} )]\n'
                f"position = Vector2( {px}, {py} )\n"
                f'target_scene = "{spec["target"]}"\n'
            )
        elif sym == "S":
            pool, limit = spawner_cfgs[spawner_i]
            spawner_i += 1
            ids = [ext_ids[p] for p in pool]
            nodes.append(
                f'[node name="{node_name}" parent="." instance=ExtResource( {ext_ids["spawner"]} )]\n'
                f"position = Vector2( {px}, {py} )\n"
                f"enemies = [ {', '.join(f'ExtResource( {i} )' for i in ids)} ]\n"
                f"limit = {limit}\n"
            )
        elif sym == "^":
            nodes.append(
                f'[node name="{node_name}" parent="." instance=ExtResource( {ext_ids["spikes"]} )]\n'
                f"position = Vector2( {px}, {row * TILE + TILE - 1} )\n"
            )
        else:
            scene_key = spec["boss"] if sym == "B" else SYM_TO_KEY.get(sym, sym)
            nodes.append(
                f'[node name="{node_name}" parent="." instance=ExtResource( {ext_ids[scene_key]} )]\n'
                f"position = Vector2( {px}, {py} )\n"
            )

    for i, (c, r) in enumerate(lava_cells, 1):
        px, py = cell_center(c, r)
        nodes.append(
            f'[node name="Lava{i}" parent="." instance=ExtResource( {ext_ids["lava"]} )]\n'
            f"position = Vector2( {px}, {py} )\n"
        )

    for i, (kind, col, flip) in enumerate(spec.get("decor", []), 1):
        path, z, tint = DECOR[kind]
        w, h = png_size(path)
        row = next((r for r in range(height) if rows[r][col] == "#"), None)
        assert row is not None, f"{spec['path']}: decor {kind} at ({col}) not above ground"
        px = col * TILE + TILE // 2 - w // 2
        py = row * TILE - h + 8
        node = (
            f'[node name="Decor{kind.title()}{i}" type="Sprite2D" parent="."]\n'
            f"position = Vector2( {px}, {py} )\n"
            f"z_index = {z}\n"
            "centered = false\n"
        )
        if flip:
            node += "flip_h = true\n"
        if tint:
            node += f"modulate = Color( {tint[0]}, {tint[1]}, {tint[2]}, 1 )\n"
        node += f"texture = ExtResource( {ext_ids['decor_' + kind]} )\n"
        nodes.append(node)

    tile_bytes = encode_cells(cells)
    tile_text = ", ".join(map(str, tile_bytes))

    # player + initPos + tilemap + env
    m = next(e for e in spec["entities"] if e[0] == "M")
    px, py = cell_center(m[1], m[2])
    nodes.insert(0, f'[node name="Player" parent="." instance=ExtResource( {ext_ids["player"]} )]\nposition = Vector2( {px}, {py} )\ncollision_layer = 2049\ncollision_mask = 2049\n')
    nodes.insert(1, f'[node name="TileMap" type="TileMapLayer" parent="."]\ntile_set = ExtResource( {ext_ids[tileset_key]} )\ntile_map_data = PackedByteArray({tile_text})\n')
    nodes.insert(2, f'[node name="initPos" type="Marker2D" parent="."]\nposition = Vector2( {px}, {py} )\n')
    nodes.insert(3, (
        '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]\n'
        "environment = SubResource( 1 )\n"
    ))
    ground_y = next(r * TILE for r in range(height) if rows[r][0] == "#")
    nodes.insert(4, (
        f'[node name="Backdrop" parent="." instance=ExtResource( {ext_ids["backdrop"]} )]\n'
        f"ground_y = {ground_y}\n"
    ))

    load_steps = len(ext) + 1 + 1  # ext resources + environment sub_resource + scene
    out = [f"[gd_scene load_steps={load_steps} format=2]", ""]
    out += ext_lines
    out += [
        "",
        '[sub_resource type="Environment" id=1]',
        "background_mode = 4",
        "fog_enabled = true",
        "fog_light_color = Color( 0, 0, 0, 1 )",
        "glow_enabled = true",
        "glow_blend_mode = 0",
        "",
        '[node name="World" type="Node"]',
        "",
    ]
    out += [n if n.endswith("\n") else n + "\n" for n in nodes]
    return "\n".join(out), len(cells), len(spec["entities"])


def main():
    manifest = {}
    for spec in LEVELS:
        text, n_cells, n_entities = build_level(spec)
        path = ROOT / spec["path"]
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        manifest["res://" + spec["path"]] = {"cells": n_cells, "entities": n_entities}
        print(f"{spec['path']}: {n_cells} tiles, {n_entities} entities, target={spec['target']}")
    OUT_MANIFEST.write_text(json.dumps(manifest, indent=1))
    print(f"Wrote {OUT_MANIFEST}")


if __name__ == "__main__":
    main()
