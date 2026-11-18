extends SceneTree

# Verifies the upgrade pickups: Levels/2 contains the wall-jump and double-jump
# pickups, touching each sets only its own flag, and the old per-level toggle
# is gone while the start menu still resets both upgrades.
# Run: godot --headless --path . --script tools/verify_upgrades.gd

var frames := 0
var stage := 0
var level
var player
var wall_pickup
var double_pickup
var passed := true


func _process(_delta: float) -> bool:
	frames += 1
	var g = root.get_node("global")

	if stage == 0 and frames == 2:
		stage = 1
		level = load("res://Levels/2.tscn").instantiate()
		root.add_child(level)
		player = level.find_child("Player", true, false)
		wall_pickup = level.find_child("WallJumpPickup", true, false)
		double_pickup = level.find_child("DoubleJumpPickup", true, false)
		_check(player != null, "player found")
		_check(wall_pickup != null, "wall jump pickup placed in Levels/2")
		_check(double_pickup != null, "double jump pickup placed in Levels/2")
		if wall_pickup == null or double_pickup == null:
			_finish()
			return false
		_check(wall_pickup.global_position.x < double_pickup.global_position.x,
			"wall jump pickup comes before the double jump pickup")
		_check(wall_pickup.get("upgrade") == "wall_jump", "wall pickup grants wall_jump")
		_check(double_pickup.get("upgrade") == "double_jump", "double pickup grants double_jump")

		g.wall_jump = false
		g.double_jump_active = false
		player.global_position = wall_pickup.global_position
		return false

	if stage == 1 and frames > 6:
		stage = 2
		_check(g.wall_jump == true, "touching wall pickup sets global.wall_jump")
		_check(g.double_jump_active == false, "wall pickup does not grant double jump")
		_check(not is_instance_valid(wall_pickup), "wall pickup is consumed")
		player.global_position = double_pickup.global_position
		return false

	if stage == 2 and frames > 25:
		stage = 3
		_check(g.double_jump_active == true, "touching double pickup sets global.double_jump_active")
		_check(g.wall_jump == true, "double pickup keeps wall jump")

		var next_level_src := FileAccess.get_file_as_string("res://Scripts/NextLevel.gd")
		_check(not next_level_src.contains("double_jump_active"),
			"NextLevel no longer toggles the double jump upgrade")

		var menu_src := FileAccess.get_file_as_string("res://StartMenu.gd")
		_check(menu_src.contains("global.double_jump_active = false"),
			"StartMenu resets the double jump upgrade")
		_check(menu_src.contains("global.wall_jump = false"),
			"StartMenu resets the wall jump upgrade")
		_finish()

	return false


func _finish() -> void:
	if level != null:
		level.free()
	print("RESULT: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		passed = false
		print("FAIL ", label)
