extends SceneTree

# Loads every scene, instantiates the level scenes and checks the migrated
# TileMapLayer / SpriteFrames / AnimationPlayer data. Run headless:
#   godot --headless --path . --script tools/verify_migration.gd

const TILEMAP_SCENES := {
	"res://World.tscn": 7203,
	"res://World2.tscn": 64,
	"res://Levels/1.tscn": 122,
	"res://Levels/2.tscn": 138,
}

const OTHER_SCENES := [
	"res://StartMenu.tscn",
	"res://EnemyH.tscn",
	"res://ForestTileSet.tscn",
	"res://JungleTileSet.tscn",
	"res://LavaTileSet.tscn",
	"res://Objects/Blood.tscn",
	"res://Objects/BrokenWall.tscn",
	"res://Objects/Bullet.tscn",
	"res://Objects/BulletEnemy.tscn",
	"res://Objects/BulletEnemy2.tscn",
	"res://Objects/BulletEnemy3.tscn",
	"res://Objects/Chave.tscn",
	"res://Objects/Door.tscn",
	"res://Objects/Explosion.tscn",
	"res://Objects/Lava.tscn",
	"res://Objects/NextLevel.tscn",
	"res://Objects/PlatformH.tscn",
	"res://Objects/Player.tscn",
	"res://Objects/Spikes.tscn",
	"res://Objects/Spwaner.tscn",
	"res://Objects/Stairs.tscn",
	"res://Objects/Effects/Explosion.tscn",
	"res://Objects/Effects/Obj.tscn",
	"res://Objects/Enemies/Boss1.tscn",
	"res://Objects/Enemies/Boss2.tscn",
	"res://Objects/Enemies/Boss3.tscn",
	"res://Objects/Enemies/Enemy1.tscn",
	"res://Objects/Enemies/Enemy2.tscn",
	"res://Objects/Enemies/Enemy3.tscn",
	"res://Objects/Enemies/Enemy4.tscn",
	"res://Objects/Enemies/Enemy5.tscn",
	"res://Objects/Enemies/Enemy7.tscn",
	"res://Objects/Enemies/Enemy9.tscn",
	"res://Objects/Enemies/Enemy11.tscn",
	"res://Objects/Enemies/Enemy12.tscn",
	"res://Objects/Enemies/Fly1.tscn",
	"res://Objects/Enemies/Fly2.tscn",
	"res://Objects/Enemies/Walker.tscn",
]


func _init() -> void:
	var failures := 0

	for path in TILEMAP_SCENES:
		var ps = load(path)
		if ps == null:
			print("FAIL load: ", path)
			failures += 1
			continue
		var node = ps.instantiate()
		var layer: TileMapLayer = node.find_child("TileMap", true, false)
		if layer == null:
			print("FAIL no TileMapLayer: ", path)
			failures += 1
			continue
		var count: int = layer.get_used_cells().size()
		var expected: int = TILEMAP_SCENES[path]
		if count != expected:
			print("FAIL cells %s: %d != expected %d" % [path, count, expected])
			failures += 1
		else:
			print("OK %s cells=%d" % [path, count])
		node.free()

	var ts = load("res://Assets/JungleDirtTileSet.tres")
	if ts is TileSet and ts.get_source_count() == 1:
		var src = ts.get_source(0)
		print("OK tileset tiles=%d physics=%s" % [src.get_tiles_count(), ts.get_physics_layers_count()])
	else:
		print("FAIL tileset load")
		failures += 1

	var player_ps = load("res://Objects/Player.tscn")
	var player = player_ps.instantiate()
	var sprite: AnimatedSprite2D = player.get_node("Sprite2D")
	var anims: PackedStringArray = sprite.sprite_frames.get_animation_names()
	if anims.has("idle") and anims.has("run") and anims.has("jump"):
		print("OK player animations: ", anims)
	else:
		print("FAIL player animations: ", anims)
		failures += 1
	var ap: AnimationPlayer = player.get_node("AnimationPlayer")
	if "Attack" in ap.get_animation_list():
		print("OK player Attack animation")
	else:
		print("FAIL player Attack animation: ", ap.get_animation_list())
		failures += 1
	player.free()

	var expl = load("res://Objects/Explosion.tscn").instantiate()
	var eap: AnimationPlayer = expl.get_node("AnimationPlayer")
	if "explosion" in eap.get_animation_list():
		print("OK explosion animation")
	else:
		print("FAIL explosion animation: ", eap.get_animation_list())
		failures += 1
	expl.free()

	for path in OTHER_SCENES:
		var ps = load(path)
		if ps == null:
			print("FAIL load: ", path)
			failures += 1
			continue
		var node = ps.instantiate()
		if node == null:
			print("FAIL instantiate: ", path)
			failures += 1
		else:
			node.free()
	print("scenes checked: ", OTHER_SCENES.size())

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
