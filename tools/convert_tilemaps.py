#!/usr/bin/env python3
"""One-shot Godot 3 -> Godot 4 TileMap/TileSet migration helper for this project.

- Parses the Godot 3 TileSet .tres files (single-tile entries with texture,
  region, collision shapes, occluders).
- Rewrites the 4 scenes' TileMap nodes as TileMapLayer nodes, re-encoding
  Godot 3 `tile_data` triplets into Godot 4 `tile_map_data` bytes.
- Emits /tmp/opencode/tileset_data.json consumed by tools/build_tileset.gd,
  which rebuilds the .tres files through the real Godot 4 TileSet API.
"""
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TILE = 32
OUT_JSON = Path("/tmp/opencode/tileset_data.json")

SCENES = [
    "World.tscn",
    "World2.tscn",
    "Levels/1.tscn",
    "Levels/2.tscn",
]
TILESETS = [
    "Assets/JungleDirtTileSet.tres",
    "Assets/JungleDirtTile2.tres",
]


def s16(v: int) -> int:
    v &= 0xFFFF
    return v - 0x10000 if v >= 0x8000 else v


def parse_numbers(body: str):
    return [float(x) if "." in x else int(x) for x in re.findall(r"-?\d+(?:\.\d+)?", body)]


def parse_rect(s: str):
    nums = parse_numbers(s)
    return tuple(nums[:4])  # x, y, w, h


def parse_vec2(s: str):
    nums = parse_numbers(s)
    return tuple(nums[:2])


def parse_transform2d(s: str):
    nums = parse_numbers(s)
    return tuple(nums[:6])  # a, b, c, d, ox, oy


def parse_packed_vec2_array(s: str):
    nums = parse_numbers(s)
    return list(zip(nums[0::2], nums[1::2]))


def parse_g3_tileset(path: Path) -> dict:
    text = path.read_text()

    ext_resources = {}
    for m in re.finditer(r'\[ext_resource path="([^"]+)" type="([^"]+)" id=(\d+)\]', text):
        ext_resources[int(m.group(3))] = m.group(1)

    sub_resources = {}
    for m in re.finditer(r"\[sub_resource type=\"(\w+)\" id=(\d+)\]\n(.*?)(?=\n\[|\Z)", text, re.S):
        stype, sid, body = m.group(1), int(m.group(2)), m.group(3)
        entry = {"type": stype}
        if stype == "RectangleShape2D":
            mm = re.search(r"extents = Vector2\(([^)]*)\)", body)
            entry["extents"] = parse_vec2(mm.group(1)) if mm else (16, 16)
        elif stype == "OccluderPolygon2D":
            mm = re.search(r"polygon = PackedVector2Array\(([^)]*)\)", body)
            entry["polygon"] = parse_packed_vec2_array(mm.group(1)) if mm else []
        sub_resources[sid] = entry

    tiles = {}
    # Tile entries look like:  ^<id>/name = "x" ... until the next id block or [resource] end.
    for m in re.finditer(r"^(\d+)/name = \"[^\"]*\"\n(.*?)(?=^\d+/name|\Z)", text, re.S | re.M):
        tid, body = int(m.group(1)), m.group(2)
        entry = {"shapes": [], "occluder": None}
        mm = re.search(r"^\d+/texture = ExtResource\(\s*(\d+)\s*\)", body, re.M)
        entry["texture"] = ext_resources[int(mm.group(1))]
        mm = re.search(r"^\d+/region = Rect2\(([^)]*)\)", body, re.M)
        entry["region"] = parse_rect(mm.group(1)) if mm else None
        mm = re.search(r"^\d+/occluder = SubResource\(\s*(\d+)\s*\)", body, re.M)
        if mm:
            entry["occluder"] = sub_resources[int(mm.group(1))]["polygon"]
        # shapes = [ { ... } ]
        sm = re.search(r"^\d+/shapes = \[\s*(\{.*?\})\s*\]", body, re.S | re.M)
        if sm:
            blob = sm.group(1)
            for one in re.finditer(r"\{([^{}]*)\}", blob):
                d = one.group(1)
                shape = {}
                mm = re.search(r'"shape": SubResource\(\s*(\d+)\s*\)', d)
                sub = sub_resources[int(mm.group(1))] if mm else None
                mm = re.search(r'"shape_transform": Transform2D\(([^)]*)\)', d)
                transform = parse_transform2d(mm.group(1)) if mm else (1, 0, 0, 1, 0, 0)
                shape["transform"] = transform
                shape["one_way"] = '"one_way": true' in d
                mm = re.search(r'"one_way_margin": ([\d.]+)', d)
                shape["one_way_margin"] = float(mm.group(1)) if mm else 1.0
                if sub and sub["type"] == "RectangleShape2D":
                    ex, ey = sub["extents"]
                    corners = [(-ex, -ey), (ex, -ey), (ex, ey), (-ex, ey)]
                    a, b, c, d2, ox, oy = transform
                    pts = [(a * px + c * py + ox, b * px + d2 * py + oy) for px, py in corners]
                    shape["points"] = [(x - TILE / 2, y - TILE / 2) for x, y in pts]
                else:
                    shape["points"] = []
                entry["shapes"].append(shape)
        tiles[tid] = entry
    return {"textures": sorted(set(ext_resources.values())), "tiles": tiles}


def build_json(tilesets: dict):
    out = []
    for rel_path, parsed in tilesets.items():
        textures = parsed["textures"]
        tiles_out = []
        skipped = 0
        for tid, t in parsed["tiles"].items():
            rx, ry, rw, rh = t["region"]
            if (rx, ry, rw, rh) == (0, 0, 0, 0):
                skipped += 1
                continue
            if rw != TILE or rh != TILE or rx % TILE != 0 or ry % TILE != 0:
                print(f"  ! {rel_path}: tile {tid} region {t['region']} not 32x32 grid-aligned -> skipped")
                skipped += 1
                continue
            tiles_out.append({
                "id": tid,
                "texture": t["texture"],
                "atlas": [rx // TILE, ry // TILE],
                "shapes": t["shapes"],
                "occluder": t["occluder"],
            })
        out.append({
            "name": rel_path,
            "out_path": "res://" + rel_path,
            "textures": textures,
            "tiles": tiles_out,
            "skipped": skipped,
        })
    return out


def patch_scene(root: Path, rel: str, id_map: dict) -> None:
    path = root / rel
    text = path.read_text()

    tile_data_re = re.compile(
        r"tile_data = (?:PoolIntArray|PackedInt32Array)\(([-\d\s,]+)\)", re.S
    )
    block_re = re.compile(
        r'(\[node name="[^"]+" type="TileMap" parent="[^"]*"\]\n)(.*?)(?=\n\[node |\Z)',
        re.S,
    )

    stats = []

    def convert(m):
        head, body = m.group(1), m.group(2)
        td = tile_data_re.search(body)
        if not td:
            print(f"  ! {rel}: TileMap node without tile_data left untouched")
            return m.group(0)
        ints = parse_numbers(td.group(1))
        assert len(ints) % 3 == 0, f"{rel}: tile_data not triplet-multiple"
        cells = []
        for i in range(0, len(ints), 3):
            raw, tid, flags = ints[i], ints[i + 1], ints[i + 2]
            if flags != 0:
                print(f"  ! {rel}: cell with non-zero flags {flags} (flips lost)")
            v32 = raw & 0xFFFFFFFF
            x, y = s16(v32 & 0xFFFF), s16((v32 >> 16) & 0xFFFF)
            if tid not in id_map:
                raise SystemExit(f"{rel}: tile id {tid} missing in tileset mapping")
            src, ax, ay = id_map[tid]
            cells.append((x, y, src, ax, ay))
        data = struct.pack("<H", 0) + b"".join(
            struct.pack("<hhhhhh", x, y, src, ax, ay, 0) for x, y, src, ax, ay in cells
        )
        txt = "tile_map_data = PackedByteArray(" + ", ".join(map(str, data)) + ")"
        new_body = tile_data_re.sub(lambda _: txt, body)
        new_body = re.sub(r"^cell_size = [^\n]*\n", "", new_body, flags=re.M)
        new_body = re.sub(r"^format = [^\n]*\n", "", new_body, flags=re.M)
        xs = [c[0] for c in cells]
        ys = [c[1] for c in cells]
        print(
            f"  {rel}: {len(cells)} cells, x[{min(xs)}..{max(xs)}] y[{min(ys)}..{max(ys)}],"
            f" {len(data)} bytes"
        )
        stats.append(len(cells))
        return head.replace('type="TileMap"', 'type="TileMapLayer"') + new_body

    new_text, n = block_re.subn(convert, text)
    if n == 0:
        print(f"  ! {rel}: no TileMap node found")
        return
    assert stats, f"{rel}: TileMap found but no data converted"
    path.write_text(new_text)
    print(f"  {rel}: node patched (type=TileMapLayer, name preserved)")


def main() -> None:
    tilesets = {}
    for rel in TILESETS:
        print(f"Parsing {rel} ...")
        tilesets[rel] = parse_g3_tileset(ROOT / rel)
        print(f"  {len(tilesets[rel]['tiles'])} tiles, textures={tilesets[rel]['textures']}")

    json_out = build_json(tilesets)
    OUT_JSON.write_text(json.dumps(json_out, indent=1))
    print(f"Wrote {OUT_JSON}")

    # Build the id -> (source, atlas) map for the tileset actually used by scenes
    # (JungleDirtTileSet.tres: single texture => source id 0).
    used = json_out[0]
    textures = used["textures"]
    id_map = {}
    for t in used["tiles"]:
        sid = textures.index(t["texture"])
        id_map[t["id"]] = (sid, t["atlas"][0], t["atlas"][1])
    print("Tile id map (source, atlas):", id_map)

    print("\nPatching scenes ...")
    for rel in SCENES:
        patch_scene(ROOT, rel, id_map)


if __name__ == "__main__":
    main()
