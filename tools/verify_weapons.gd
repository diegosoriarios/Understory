extends SceneTree

# Verifies the Contra weapon pass: hold-to-fire cadence per weapon, weapon
# pickups grant their gun, weapon resets on death, and the start menu resets
# the weapon.
# Run: godot --headless --path . --script tools/verify_weapons.gd

var stage := 0
var stage_frames := 0
var world
var player
var passed := true
var normal_count := 0
var machine_mark := 0


func _physics_process(_delta: float) -> bool:
	stage_frames += 1
	match stage:
		0:
			_build_world()
			_go(1)
		1:
			if player.is_on_floor():
				_check(player.weapon == 0, "player starts with the normal gun")
				_check(player.hud_weapon.text == "N", "HUD shows N")
				Input.action_press("shoot")
				_go(2)
		2:
			if stage_frames >= 40:
				normal_count = _bullet_count()
				_check(normal_count >= 2, "hold-to-fire normal gun fires repeatedly (%d)" % normal_count)
				Input.action_release("shoot")
				player.pick_weapon(1)
				_go(3)
		3:
			if stage_frames >= 2:
				_check(player.weapon == 1, "pick_weapon grants the machine gun")
				_check(root.get_node("global").weapon == 1, "global.weapon persists the machine gun")
				_check(player.hud_weapon.text == "M", "HUD shows M")
				machine_mark = _bullet_count()
				Input.action_press("shoot")
				_go(4)
		4:
			if stage_frames >= 40:
				var fired = _bullet_count() - machine_mark
				_check(fired >= 4, "machine gun out-paces the normal gun (%d in 40 frames)" % fired)
				Input.action_release("shoot")
				_spawn_spread_pickup()
				_go(5)
		5:
			if stage_frames >= 4:
				_check(player.weapon == 2, "spread pickup grants the spread gun")
				_check(player.hud_weapon.text == "S", "HUD shows S")
				_check("Spread" in player.hud_toast.text, "pickup shows a toast")
				_go(6)
		6:
			_text_checks()
			_finish()
	if stage_frames > 900 and stage < 6:
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
	var floor_shape = CollisionShape2D.new()
	var floor_rect = RectangleShape2D.new()
	floor_rect.size = Vector2(2000, 40)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(500, 400)
	world.add_child(floor_body)

	player = load("res://Objects/Player.tscn").instantiate()
	player.global_position = Vector2(250, 340)
	world.add_child(player)


func _spawn_spread_pickup() -> void:
	var pickup = load("res://Objects/WeaponPickup.tscn").instantiate()
	pickup.kind = "spread"
	pickup.global_position = player.global_position
	world.add_child(pickup)


func _bullet_count() -> int:
	var n = 0
	for c in world.get_children():
		if c is CharacterBody2D and c != player:
			n += 1
	return n


func _text_checks() -> void:
	var player_src := FileAccess.get_file_as_string("res://Scripts/Player.gd")
	_check("global.weapon = WEAPON_NORMAL" in player_src, "death resets the weapon to normal")
	var menu_src := FileAccess.get_file_as_string("res://StartMenu.gd")
	_check(menu_src.contains("global.weapon = 0"), "start menu resets the weapon")


func _finish() -> void:
	Input.action_release("shoot")
	Input.action_release("jump")
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
