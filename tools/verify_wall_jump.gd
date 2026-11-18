extends SceneTree

# Verifies the Celeste-style wall movement against a synthetic wall:
# a ground jump next to a wall is not a wall jump, wall contact while falling
# caps the fall speed, and the wall jump pushes away from the wall at full
# height while keeping one air jump available.
# Run: godot --headless --path . --script tools/verify_wall_jump.gd

const WALL_SLIDE_SPEED = 60.0

var stage := 0
var stage_frames := 0
var world
var player
var passed := true


func _physics_process(_delta: float) -> bool:
	stage_frames += 1
	var g = root.get_node("global")

	match stage:
		0:
			g.wall_jump = true
			g.double_jump_active = false
			_build_world()
			_go(1)
		1:
			if player.is_on_floor():
				_check(true, "player landed on the test floor")
				Input.action_press("ui_right")
				_go(2)
		2:
			if player.is_on_wall():
				_check(true, "player reached the wall by walking")
				Input.action_press("ui_up")
				_go(3)
		3:
			if stage_frames >= 2:
				Input.action_release("ui_up")
				_check(player.wall_lock <= 0.0, "ground jump next to a wall is not a wall jump")
				_check(player.motion.y < -300.0, "ground jump still uses full jump force")
				_go(4)
		4:
			if player.is_on_wall() and not player.is_on_floor() \
					and player.motion.y >= WALL_SLIDE_SPEED - 1.0 and player.motion.y > 0.0:
				_check(player.motion.y <= WALL_SLIDE_SPEED + 0.01,
					"falling against the wall is capped at wall-slide speed")
				_check(player.jumps == 1, "wall slide keeps the air jump available")
				Input.action_press("ui_up")
				_go(5)
		5:
			Input.action_release("ui_up")
			_go(6)
		6:
			if stage_frames >= 2:
				_check(player.motion.y < -300.0, "wall jump restores full jump force")
				_check(player.motion.x < 0.0, "wall jump pushes away from the right-side wall")
				_check(player.face_right == false, "wall jump faces away from the wall")
				_check(player.jumps == 1, "wall jump leaves one air jump")
				_check(player.wall_lock > 0.0, "wall jump locks steering briefly")
				Input.action_release("ui_right")
				g.double_jump_active = true
				Input.action_press("ui_up")
				_go(7)
		7:
			Input.action_release("ui_up")
			_go(8)
		8:
			if stage_frames >= 2:
				_check(player.jumps == 2, "double jump is available after a wall jump")
				_check(player.motion.y < -300.0, "double jump restores full jump force")
				_finish()

	if stage_frames > 900 and stage < 8:
		_check(false, "test timed out at stage %d" % stage)
		_finish()

	return false


func _go(next_stage: int) -> void:
	stage = next_stage
	stage_frames = 0


func _build_world() -> void:
	world = Node2D.new()
	world.name = "TestWorld"
	root.add_child(world)

	var floor_body = StaticBody2D.new()
	floor_body.name = "Floor"
	var floor_shape = CollisionShape2D.new()
	var floor_rect = RectangleShape2D.new()
	floor_rect.size = Vector2(2000, 40)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(500, 400)
	world.add_child(floor_body)

	var wall = StaticBody2D.new()
	wall.name = "Wall"
	var wall_shape = CollisionShape2D.new()
	var wall_rect = RectangleShape2D.new()
	wall_rect.size = Vector2(40, 300)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall.position = Vector2(320, 250)
	world.add_child(wall)

	player = load("res://Objects/Player.tscn").instantiate()
	player.global_position = Vector2(250, 340)
	world.add_child(player)


func _finish() -> void:
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Input.action_release("ui_up")
	if world != null:
		world.free()
	print("RESULT: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		passed = false
		print("FAIL ", label)
