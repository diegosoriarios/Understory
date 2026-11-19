extends SceneTree

# Verifies the art pass wiring in the generated scenes and object scenes:
# parallax backdrop, grass autotile variants, stone boss tilesets, decor,
# lava/spike geometry and non-placeholder object textures.
# Run: godot --headless --path . --script tools/verify_visuals.gd

const LEVELS := [
	"res://World.tscn",
	"res://Levels/1.tscn",
	"res://Levels/2.tscn",
	"res://Levels/3.tscn",
	"res://Levels/4.tscn",
	"res://Levels/5.tscn",
]
const STONE_LEVELS := ["res://Levels/3.tscn", "res://Levels/4.tscn", "res://Levels/5.tscn"]

var failures := 0


func check(ok: bool, label: String) -> void:
	if ok:
		print("OK ", label)
	else:
		print("FAIL ", label)
		failures += 1


func _init() -> void:
	for path in LEVELS:
		var node = load(path).instantiate()
		check_level(path, node)
		node.free()

	check_enemies()
	check_player()
	check_object_texture("res://Objects/NextLevel.tscn", "Portal")
	check_object_texture("res://Objects/Door.tscn", "Door")
	check_object_texture("res://Objects/Chave.tscn", "Key")

	var lava = load("res://Objects/Lava.tscn").instantiate()
	var lava_sprite: Sprite2D = lava.get_node_or_null("Sprite2D")
	check(lava_sprite != null and lava_sprite.texture != null and lava_sprite.region_enabled,
		"lava sprite has texture and region")
	lava.free()

	var spikes = load("res://Objects/Spikes.tscn").instantiate()
	var spike_sprite: Sprite2D = spikes.get_node_or_null("Shape3D")
	check(spike_sprite != null and spike_sprite.texture != null, "spikes sprite has texture")
	spikes.free()

	var pickup = load("res://Objects/WeaponPickup.tscn").instantiate()
	var spr: Sprite2D = pickup.get_node_or_null("Sprite2D")
	var mat: CanvasItemMaterial = null
	if spr:
		mat = spr.material as CanvasItemMaterial
	check(mat != null and mat.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD,
		"weapon pickup uses additive blend")
	check(pickup.get_node_or_null("Letter") != null, "weapon pickup has a weapon letter")
	pickup.free()

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func check_level(path: String, node: Node) -> void:
	var backdrop := node.find_child("Backdrop", true, false)
	check(backdrop != null, "%s has backdrop" % path)
	if backdrop:
		for layer_name in ["Sky", "Far", "Mid", "Near"]:
			var layer := backdrop.get_node_or_null(layer_name)
			var sprite: Sprite2D = layer.get_node_or_null("Sprite") if layer else null
			check(sprite != null and sprite.texture != null,
				"%s backdrop %s textured" % [path, layer_name])

	var tilemap: TileMapLayer = node.find_child("TileMap", true, false)
	check(tilemap != null and tilemap.tile_set != null, "%s has tileset" % path)
	if tilemap and tilemap.tile_set:
		var atlas := tilemap.tile_set.get_source(0) as TileSetAtlasSource
		var grass := true
		for coords in [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(4, 5)]:
			if atlas == null or atlas.get_tile_data(coords, 0) == null:
				grass = false
		check(grass, "%s tileset defines grass caps and fill" % path)
		var stone := str(tilemap.tile_set.resource_path).contains("Stone")
		check(stone == (path in STONE_LEVELS), "%s tileset biome" % path)

	var decor := 0
	for child in node.find_children("Decor*", "Sprite2D", true, false):
		if child.texture != null:
			decor += 1
	check(decor >= 3, "%s has decor sprites (%d)" % [path, decor])


func check_enemies() -> void:
	var scenes := {
		"Walker": "walker", "Enemy1": "enemy1", "Enemy2": "enemy2", "Enemy3": "enemy3",
		"Enemy4": "enemy4", "Enemy5": "enemy5", "Enemy7": "enemy7", "Enemy9": "enemy9",
		"Enemy11": "enemy11", "Enemy12": "enemy12", "Fly1": "fly1", "Fly2": "fly2",
		"Boss1": "boss1", "Boss2": "boss2", "Boss3": "boss3",
	}
	for scene in scenes:
		var node = load("res://Objects/Enemies/%s.tscn" % scene).instantiate()
		var sprite: AnimatedSprite2D = node.find_child("icon", true, false)
		if sprite == null:
			sprite = node.find_child("Sprite2D", true, false)
		check(sprite != null, "%s has animated sprite" % scene)
		if sprite:
			var frames := sprite.sprite_frames
			check(frames != null and frames.has_animation("move") and frames.get_frame_count("move") == 2,
				"%s has two-frame move animation" % scene)
			var tex_path := str(frames.get_frame_texture("move", 0).resource_path) if frames else ""
			check(tex_path.contains("Assets/Sprites/Enemies/Kenney/%s_" % scenes[scene]),
				"%s uses Kenney enemy art" % scene)
		node.free()


func check_player() -> void:
	var player = load("res://Objects/Player.tscn").instantiate()
	var sprite: AnimatedSprite2D = player.get_node_or_null("Sprite2D")
	check(sprite != null, "player has animated sprite")
	if sprite:
		var frames := sprite.sprite_frames
		check(frames.has_animation("idle") and frames.get_frame_count("idle") == 1,
			"player idle has one frame")
		check(frames.has_animation("run") and frames.get_frame_count("run") == 2,
			"player run has two frames")
		check(frames.has_animation("jump") and frames.get_frame_count("jump") == 1,
			"player jump has one frame")
		var tex := str(frames.get_frame_texture("idle", 0).resource_path)
		check(tex.contains("Assets/Sprites/Player/"), "player uses Kenney alien art")
		check(is_equal_approx(sprite.scale.x, 0.3) and is_equal_approx(sprite.position.y, -16.2),
			"player sprite scale and ground alignment")
	player.free()


func check_object_texture(path: String, label: String) -> void:
	var node = load(path).instantiate()
	var sprite: Sprite2D = node.get_node_or_null("Sprite2D")
	var tex_path := str(sprite.texture.resource_path) if sprite and sprite.texture else ""
	check(tex_path != "" and not tex_path.ends_with("icon.png"), "%s uses dedicated art" % label)
	node.free()
