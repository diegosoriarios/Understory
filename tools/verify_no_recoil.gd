extends SceneTree

# Verifies that shooting no longer moves the player (recoil/teleport bug).
# Loads Levels/1, lets the player settle on the ground, then compares
# position/motion before and after calling shoot().
# Run: godot --headless --path . --script tools/verify_no_recoil.gd

var frames := 0
var level
var player
var started := false
var passed := true
var shots := 0


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2 and not started:
		started = true
		level = load("res://Levels/1.tscn").instantiate()
		root.add_child(level)
		player = level.find_child("Player", true, false)
		_check(player != null, "player found")

	elif frames == 30 and started:
		var bullets_before := _count_bullets()
		var pos_before: Vector2 = player.global_position
		var motion_before: Vector2 = player.motion
		player.shoot()
		var bullets_after := _count_bullets()
		_check(_count_bullets() > bullets_before, "shoot() spawned a bullet")
		_check(player.global_position.is_equal_approx(pos_before), "position unchanged after shot")
		_check(player.motion.is_equal_approx(motion_before), "motion unchanged after shot")

		# Repeat while moving to cover the running case (the old bug scaled
		# the teleport by the full horizontal speed).
		player.motion.x = 200.0
		var pos_run: Vector2 = player.global_position
		var motion_run: Vector2 = player.motion
		player.shoot()
		_check(player.global_position.is_equal_approx(pos_run), "position unchanged when running")
		_check(player.motion.is_equal_approx(motion_run), "motion unchanged when running")

		print("RESULT: ", "PASS" if passed else "FAIL")
		quit(0 if passed else 1)
	return false


func _count_bullets() -> int:
	var n := 0
	for child in level.get_children():
		if child.has_method("start") and child is CharacterBody2D:
			n += 1
	return n


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		passed = false
		print("FAIL ", label)
