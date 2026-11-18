extends SceneTree

# Verifies bullet physics isolation and the Enemy12 bomb arc:
# bullet bodies live on their own layer with an empty mask (so bullets never
# block or destroy each other), their Area2D still hits the world/player, and
# the bomb bullet moves in one consistent, bounded arc.
# Run: godot --headless --path . --script tools/verify_bullet_isolation.gd

const BULLET_LAYER := 16

var stage := 0
var stage_frames := 0
var world
var player_bullet
var enemy_bullet
var fake_player
var level
var bomb
var bomb_start_y := 0.0
var last_bomb_pos := Vector2.ZERO
var max_bomb_step := 0.0
var passed := true
var bomb_risen := false


func _physics_process(_delta: float) -> bool:
	stage_frames += 1

	match stage:
		0:
			_check_bullet_scene("res://Objects/Bullet.tscn", "player bullet")
			_check_bullet_scene("res://Objects/BulletEnemy.tscn", "enemy bullet")
			_check_bullet_scene("res://Objects/BulletEnemy2.tscn", "bomb bullet")
			_check_bullet_scene("res://Objects/BulletEnemy3.tscn", "rocket bullet")
			_build_world()
			player_bullet = load("res://Objects/Bullet.tscn").instantiate()
			player_bullet.start(Vector2(0, -200), 0.0, _shooter())
			world.add_child(player_bullet)
			enemy_bullet = load("res://Objects/BulletEnemy.tscn").instantiate()
			enemy_bullet.start(Vector2(140, -200), PI, _shooter())
			world.add_child(enemy_bullet)
			_go(1)
		1:
			if stage_frames >= 14:
				_check(is_instance_valid(player_bullet) and is_instance_valid(enemy_bullet),
					"crossing bullets do not block or destroy each other")
				if is_instance_valid(player_bullet) and is_instance_valid(enemy_bullet):
					_check(player_bullet.position.x > enemy_bullet.position.x,
						"bullets pass through each other")
				_free(player_bullet)
				_free(enemy_bullet)
				fake_player = _make_player_stub(Vector2(400, -400))
				world.add_child(fake_player)
				enemy_bullet = load("res://Objects/BulletEnemy.tscn").instantiate()
				enemy_bullet.start(Vector2(460, -400), PI, _shooter())
				world.add_child(enemy_bullet)
				_go(2)
		2:
			if stage_frames >= 12:
				_check(fake_player.damage_taken == true, "enemy bullet still damages the player")
				_check(not is_instance_valid(enemy_bullet), "enemy bullet is freed on player contact")
				_free(fake_player)
				_free(world)
				world = null
				level = load("res://Levels/1.tscn").instantiate()
				root.add_child(level)
				player_bullet = load("res://Objects/Bullet.tscn").instantiate()
				player_bullet.start(Vector2(176, 464), 0.0, level.find_child("Player", true, false))
				level.add_child(player_bullet)
				_go(3)
		3:
			if stage_frames >= 4:
				_check(not is_instance_valid(player_bullet),
					"player bullet is freed by the TileMap instead of bouncing")
				level.free()
				level = null
				_build_world()
				bomb = load("res://Objects/BulletEnemy2.tscn").instantiate()
				bomb.start(Vector2(0, -800))
				bomb_start_y = bomb.position.y
				last_bomb_pos = bomb.position
				world.add_child(bomb)
				_go(4)
		4:
			if stage_frames >= 5:
				bomb_risen = bomb.position.y < bomb_start_y
				_check(bomb_risen, "bomb starts by rising")
				last_bomb_pos = bomb.position
				_go(5)
		5:
			if is_instance_valid(bomb):
				var step: float = bomb.position.distance_to(last_bomb_pos)
				max_bomb_step = maxf(max_bomb_step, step)
				last_bomb_pos = bomb.position
			if stage_frames >= 70:
				_check(bomb_risen and bomb.position.y > bomb_start_y, "bomb falls back down after the rise")
				_check(max_bomb_step < 20.0, "bomb never teleports between frames")
				_check(absf(bomb.position.x) < 200.0, "bomb horizontal drift stays bounded")
				_finish()

	if stage_frames > 600 and stage < 5:
		_check(false, "test timed out at stage %d" % stage)
		_finish()

	return false


func _go(next_stage: int) -> void:
	stage = next_stage
	stage_frames = 0


func _check_bullet_scene(path: String, label: String) -> void:
	var b = load(path).instantiate()
	_check(b.collision_layer == BULLET_LAYER, label + " body is on the bullets layer")
	_check(b.collision_mask == 0, label + " body collides with nothing")
	var area = b.get_node_or_null("Area2D")
	if area != null:
		_check(area.collision_layer == 0, label + " hit area is not a bullet target")
		_check(area.collision_mask == 1, label + " hit area still detects the world")
	b.free()


func _build_world() -> void:
	world = Node2D.new()
	world.name = "TestWorld"
	root.add_child(world)


func _shooter() -> StaticBody2D:
	var shooter = StaticBody2D.new()
	shooter.position = Vector2(-400, -400)
	world.add_child(shooter)
	return shooter


func _make_player_stub(pos: Vector2) -> StaticBody2D:
	var script := GDScript.new()
	script.source_code = "extends StaticBody2D\nvar damage_taken = false\nfunc set_take_damage(_v):\n\tdamage_taken = true\n"
	script.reload()
	var fake := StaticBody2D.new()
	fake.set_script(script)
	fake.name = "Player"
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48, 48)
	cs.shape = sh
	fake.add_child(cs)
	fake.position = pos
	return fake


func _free(node) -> void:
	if node != null and is_instance_valid(node):
		node.free()


func _finish() -> void:
	_free(bomb)
	_free(world)
	_free(level)
	print("RESULT: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		passed = false
		print("FAIL ", label)
