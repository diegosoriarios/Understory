extends SceneTree

# Rebuilds the Godot 4 TileSet resources from the JSON produced by
# tools/convert_tilemaps.py (path in TILESET_JSON env var).

const TILE_SIZE := 32


func _init() -> void:
	var json_path := OS.get_environment("TILESET_JSON")
	if json_path.is_empty():
		json_path = "/tmp/opencode/tileset_data.json"
	var f := FileAccess.open(json_path, FileAccess.READ)
	if f == null:
		push_error("cannot open " + json_path)
		quit(1)
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data == null:
		push_error("bad json")
		quit(1)
		return

	for ts_def in data:
		var ts := TileSet.new()
		ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_physics_layer()
		ts.add_occlusion_layer()

		var source_ids := {}
		var next_source := 0
		for tex_path in ts_def["textures"]:
			var src := TileSetAtlasSource.new()
			src.texture = load(tex_path)
			if src.texture == null:
				push_error("cannot load texture " + tex_path)
				quit(1)
				return
			src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
			ts.add_source(src, next_source)
			source_ids[tex_path] = next_source
			next_source += 1

		var created := 0
		for tile in ts_def["tiles"]:
			var tex_path: String = tile["texture"]
			var atlas := Vector2i(int(tile["atlas"][0]), int(tile["atlas"][1]))
			var src: TileSetAtlasSource = ts.get_source(source_ids[tex_path])
			src.create_tile(atlas)
			var td := src.get_tile_data(atlas, 0)
			for shape in tile["shapes"]:
				if shape["points"].is_empty():
					continue
				var pts := PackedVector2Array()
				for p in shape["points"]:
					pts.append(Vector2(float(p[0]), float(p[1])))
				var idx := td.get_collision_polygons_count(0)
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, idx, pts)
				td.set_collision_polygon_one_way(0, idx, bool(shape["one_way"]))
				td.set_collision_polygon_one_way_margin(0, idx, float(shape["one_way_margin"]))
			if tile.get("occluder") != null and not (tile["occluder"] as Array).is_empty():
				var occ := OccluderPolygon2D.new()
				var pts := PackedVector2Array()
				for p in tile["occluder"]:
					pts.append(Vector2(float(p[0]) - TILE_SIZE / 2.0, float(p[1]) - TILE_SIZE / 2.0))
				occ.polygon = pts
				td.set_occluder(0, occ)
			created += 1

		var err := ResourceSaver.save(ts, ts_def["out_path"])
		print("saved %s tiles=%d skipped=%s err=%d" % [ts_def["out_path"], created, ts_def["skipped"], err])
		if err != OK:
			quit(1)
			return
	quit()
