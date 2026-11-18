extends SceneTree

# Verifies generated campaign levels: loads each scene, checks TileMapLayer
# cell counts against the generator manifest, and instantiates everything.
# Run: godot --headless --path . --script tools/verify_levels.gd

func _init() -> void:
	var f := FileAccess.open("/tmp/opencode/levels_manifest.json", FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(f.get_as_text())
	var failures := 0

	for path in manifest:
		var expected: int = manifest[path]["cells"]
		var ps = load(path)
		if ps == null:
			print("FAIL load: ", path)
			failures += 1
			continue
		var node = ps.instantiate()
		if node == null:
			print("FAIL instantiate: ", path)
			failures += 1
			continue
		var layer: TileMapLayer = node.find_child("TileMap", true, false)
		var count: int = layer.get_used_cells().size() if layer else -1
		if count != expected:
			print("FAIL cells %s: %d != %d" % [path, count, expected])
			failures += 1
		else:
			print("OK %s cells=%d entities=%d" % [path, count, manifest[path]["entities"]])
		node.free()

	var win = load("res://Win.tscn").instantiate()
	if win == null:
		print("FAIL Win.tscn")
		failures += 1
	else:
		win.free()
		print("OK Win.tscn")

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
