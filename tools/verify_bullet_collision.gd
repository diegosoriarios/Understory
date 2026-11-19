extends SceneTree

# Headless test for bullet -> world interactions after bullets stopped being
# physics bodies: a bullet is stopped (freed) by a TileMap-named body and a
# bullet destroys a can_destroy area through its hit() method.
# Run: godot --headless --path . --script tools/verify_bullet_collision.gd

var stage := 0
var stage_frames := 0
var world
var wall_bullet
var breaker_bullet
var destructible_hit := false
var passed := true


func _physics_process(_delta: float) -> bool:
	stage_frames += 1

	match stage:
		0:
			world = Node2D.new()
			root.add_child(world)
			var dummy = _body("Dummy", Vector2(-5000, -5000), Vector2(32, 32))
			world.add_child(dummy)

			var wall = _body("TileMap", Vector2(100, 0), Vector2(64, 64))
			world.add_child(wall)
			wall_bullet = load("res://Objects/Bullet.tscn").instantiate()
			wall_bullet.start(Vector2(0, 0), 0.0, dummy)
			world.add_child(wall_bullet)

			var breaker_script := GDScript.new()
			breaker_script.source_code = "extends Area2D\nfunc hit():\n\tEngine.set_meta(\"destructible_hit\", true)\n"
			breaker_script.reload()
			var breaker := Area2D.new()
			breaker.set_script(breaker_script)
			breaker.add_to_group("can_destroy")
			var bcs := CollisionShape2D.new()
			var bcircle := CircleShape2D.new()
			bcircle.radius = 24.0
			bcs.shape = bcircle
			breaker.add_child(bcs)
			breaker.position = Vector2(100, -300)
			world.add_child(breaker)

			breaker_bullet = load("res://Objects/Bullet.tscn").instantiate()
			breaker_bullet.start(Vector2(0, -300), 0.0, dummy)
			world.add_child(breaker_bullet)
			_go(1)
		1:
			if stage_frames >= 20:
				_check(not is_instance_valid(wall_bullet), "bullet is stopped by the TileMap wall")
				_check(not is_instance_valid(breaker_bullet), "bullet is consumed by the destructible")
				_check(Engine.get_meta("destructible_hit", false), "destructible area hit() was called")
				_finish()

	if stage_frames > 400 and stage < 1:
		_check(false, "test timed out")
		_finish()

	return false


func _go(next_stage: int) -> void:
	stage = next_stage
	stage_frames = 0


func _body(body_name: String, pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = pos
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	body.add_child(cs)
	return body


func _finish() -> void:
	_free(world)
	print("RESULT: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)


func _free(node) -> void:
	if node != null and is_instance_valid(node):
		node.free()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		passed = false
		print("FAIL ", label)
