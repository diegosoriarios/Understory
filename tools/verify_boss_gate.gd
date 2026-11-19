extends SceneTree

# Verifies the boss gating chain in Levels/3.tscn:
# kill Boss (50 hits) -> Chave key spawns -> fake Player overlaps key
# -> Door.open() disables its collision.
# Run: godot --headless --path . --script tools/verify_boss_gate.gd

var frames := 0
var level
var started := false


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2 and not started:
		started = true
		var scene := OS.get_environment("GATE_SCENE")
		if scene.is_empty():
			scene = "res://Levels/3.tscn"
		var hits := int(OS.get_environment("GATE_HITS")) if OS.get_environment("GATE_HITS") != "" else 50
		level = load(scene).instantiate()
		root.add_child(level)
		var boss = level.find_child("Boss", true, false)
		print("BOSS_FOUND=", boss != null)
		for i in hits:
			boss.hit()
		var key = level.find_child("Chave", true, false)
		print("KEY_SPAWNED=", key != null)
		if key != null:
			# Free the "Player" name so the fake body keeps it (Chave checks body.name).
			level.get_node("Player").name = "RealPlayer"
			var fake_script := GDScript.new()
			fake_script.source_code = "extends StaticBody2D\nfunc set_take_damage(_v):\n\tpass\n"
			fake_script.reload()
			var fake := StaticBody2D.new()
			fake.set_script(fake_script)
			fake.name = "Player"
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(200, 200)
			cs.shape = sh
			fake.add_child(cs)
			fake.position = key.global_position
			level.add_child(fake)
	if frames == 40 and started:
		var key = level.find_child("Chave", true, false)
		if key != null:
			print("KEY_ALIVE=true pos=", key.global_position)
		else:
			print("KEY_ALIVE=false (picked up -> door opened)")
	if frames == 60 and started:
		var door = level.find_child("Door", true, false)
		# Godot clamps scale-to-zero to ~1e-05; anything below 0.01 counts as open.
		var opened: bool = door != null and door.get_node("CollisionShape2D").scale.length() < 0.01
		print("DOOR_SHAPE_SCALE=", door.get_node("CollisionShape2D").scale if door else null)
		print("DOOR_OPENED=", opened)
		print("RESULT: ", "PASS" if opened else "FAIL")
		quit(0 if opened else 1)
	return false
