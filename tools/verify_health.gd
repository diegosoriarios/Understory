extends SceneTree

# Verifies the player health system headlessly:
# hearts HUD -> damage decrements hp -> damage cooldown blocks repeats.
# Run: godot --headless --path . --script tools/verify_health.gd

var frames := 0
var level
var player
var started := false
var passed := true


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2 and not started:
		started = true
		level = load("res://Levels/1.tscn").instantiate()
		root.add_child(level)
		player = level.find_child("Player", true, false)
		print("PLAYER_FOUND=", player != null)
		print("HP_INITIAL=", player.hp)
		print("HUD_INITIAL=", player.hud_hearts.text)
		_check(player.hp == 3, "initial hp is 3")
		_check(player.hud_hearts.text == "♥♥♥", "hud shows 3 hearts")

		player.set_take_damage(true)
		_check(player.hp == 2, "first hit decrements hp to 2")
		_check(player.take_damage == true, "damage blink is active")
		_check(player.hud_hearts.text == "♥♥♡", "hud shows 2 hearts")

		player.set_take_damage(true)
		_check(player.hp == 2, "repeat hit during cooldown is ignored")

		player.set_take_damage(false)
		player.set_take_damage(true)
		_check(player.hp == 1, "hit after cooldown decrements hp to 1")

		var g = root.get_node("global")
		var deaths_before = g.deaths
		player.set_take_damage(false)
		player.set_take_damage(true)
		_check(player.hp == 0, "third hit reaches hp 0")
		_check(g.deaths == deaths_before + 1, "death increments global.deaths")

		print("RESULT: ", "PASS" if passed else "FAIL")
		quit(0 if passed else 1)
	return false


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		passed = false
		print("FAIL ", label)
