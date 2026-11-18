extends SceneTree

# Headless physics test for the bullet -> collider.hit() path.
# Spawns Bullet.tscn flying into a static wall whose script records hit().
# Run: godot --headless --path . --script tools/verify_bullet_collision.gd

var frames := 0
var hit_ok := false


class Wall:
	extends StaticBody2D

	var tree
	var hit_count := 0

	func hit():
		hit_count += 1
		hit_count = 1 if hit_count > 1 else hit_count
		tree.hit_ok = true


func _init() -> void:
	var root_node := Node2D.new()
	root.add_child(root_node)

	# Bullet._process() looks up parent/"Player"/"Camera2D" every frame.
	# find_child() defaults to owned=true, so set owners like scene instances do.
	var fake_player := Node2D.new()
	fake_player.name = "Player"
	root_node.add_child(fake_player)
	fake_player.owner = root_node
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	fake_player.add_child(cam)
	cam.owner = fake_player

	# Wall the bullet will crash into.
	var wall = Wall.new()
	wall.name = "Wall"
	wall.tree = self
	wall.position = Vector2(100, 0)
	var wshape := CollisionShape2D.new()
	var wrect := RectangleShape2D.new()
	wrect.size = Vector2(64, 64)
	wshape.shape = wrect
	wall.add_child(wshape)
	root_node.add_child(wall)

	# Far-away dummy body used as the collision exception (ignore).
	var dummy := StaticBody2D.new()
	dummy.position = Vector2(-5000, -5000)
	var dshape := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(32, 32)
	dshape.shape = drect
	dummy.add_child(dshape)
	root_node.add_child(dummy)

	var bullet = load("res://Objects/Bullet.tscn").instantiate()
	root_node.add_child(bullet)
	bullet.start(Vector2(0, 0), 0.0, dummy)


func _process(_delta: float) -> bool:
	# Process iterations outrun physics ticks in headless --script mode,
	# so gate on physics frames: 40 ticks x ~8.3px/tick covers the 68px to the wall.
	if Engine.get_physics_frames() >= 40:
		if hit_ok:
			print("RESULT: PASS (wall hit() called, physics_frames=%d)" % Engine.get_physics_frames())
			quit(0)
		else:
			print("RESULT: FAIL (wall hit() never called after %d physics frames)" % Engine.get_physics_frames())
			quit(1)
	return false
