extends SceneTree

# Verifies the control pass: gamepad bindings, crosshair cursor settings and
# the aim/jump input path on a live Player instance.
# Run: godot --headless --path . --script tools/verify_controls.gd

var failures := 0
var world: Node2D
var player


func check(ok: bool, label: String) -> void:
	if ok:
		print("OK ", label)
	else:
		print("FAIL ", label)
		failures += 1


func has_motion(action: String, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false


func has_button(action: String, index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == index:
			return true
	return false


func has_mouse(action: String, index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == index:
			return true
	return false


func has_key(action: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false


func _init() -> void:
	# --- static input map -------------------------------------------------
	check(has_motion("ui_left", 0, -1.0) and has_button("ui_left", 13), "left: stick axis + D-pad")
	check(has_motion("ui_right", 0, 1.0) and has_button("ui_right", 14), "right: stick axis + D-pad")
	check(has_motion("ui_up", 1, -1.0) and has_button("ui_up", 11), "up: stick axis + D-pad")
	check(has_motion("ui_down", 1, 1.0) and has_button("ui_down", 12), "down: stick axis + D-pad")
	check(is_equal_approx(InputMap.action_get_deadzone("ui_left"), 0.25), "movement stick deadzone")

	check(InputMap.has_action("jump") and has_key("jump", 32) and has_key("jump", 87) and has_button("jump", 0),
		"jump: Space/W + gamepad A")
	check(InputMap.has_action("crouch") and has_button("crouch", 1), "crouch: gamepad B")
	check(has_motion("aim_left", 2, -1.0) and has_motion("aim_right", 2, 1.0), "aim: right stick X")
	check(has_motion("aim_up", 3, -1.0) and has_motion("aim_down", 3, 1.0), "aim: right stick Y")
	check(has_mouse("shoot", 1) and has_motion("shoot", 5, 1.0) and has_button("shoot", 2),
		"shoot: mouse + right trigger + X")
	check(has_button("ui_accept", 0), "menu accept: gamepad A")

	# --- crosshair --------------------------------------------------------
	var cursor := str(ProjectSettings.get_setting("display/mouse_cursor/custom_image"))
	var hotspot: Vector2 = ProjectSettings.get_setting("display/mouse_cursor/custom_image_hotspot")
	check(cursor == "res://Assets/Sprites/crosshair.png", "cursor uses the new crosshair")
	check(hotspot == Vector2(36, 36), "cursor hotspot is centered")
	var texture := load("res://Assets/Sprites/crosshair.png") as Texture2D
	check(texture != null and texture.get_width() == 72 and texture.get_height() == 72,
		"crosshair texture is 72x72")

	# --- runtime aim + jump ----------------------------------------------
	# Autoload globals are not registered during SceneTree._init in --script
	# mode; let one frame pass before instantiating the Player script.
	await process_frame
	world = Node2D.new()
	root.add_child(world)

	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(1200, 40)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, 220)
	world.add_child(floor_body)

	player = load("res://Objects/Player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector2(0, 150)

	var muzzle: Marker2D = player.get_node("Muzzle")
	var gun: Sprite2D = player.get_node("Muzzle/icon")
	var reticle: Sprite2D = player.get_node("Reticle")
	var sprite: AnimatedSprite2D = player.get_node("Sprite2D")

	for i in 60:
		await physics_frame
		if player.is_on_floor():
			break
	check(player.is_on_floor(), "player landed on the test floor")

	Input.action_press("aim_right", 1.0)
	for i in 2:
		await physics_frame
	check(absf(angle_difference(muzzle.rotation, 0.0)) < 0.05, "right stick aims right")
	check(is_equal_approx(muzzle.position.x, 18.0) and not gun.flip_v, "gun sits on the right side")
	check(reticle.visible, "gamepad reticle is visible while aiming")

	Input.action_release("aim_right")
	Input.action_press("aim_left", 1.0)
	for i in 2:
		await physics_frame
	check(absf(angle_difference(muzzle.rotation, PI)) < 0.05, "right stick aims left")
	check(is_equal_approx(muzzle.position.x, -18.0) and gun.flip_v, "gun flips to the left side")

	Input.action_release("aim_left")
	Input.action_press("aim_up", 1.0)
	for i in 2:
		await physics_frame
	check(absf(angle_difference(muzzle.rotation, -PI / 2.0)) < 0.05, "right stick aims up")

	Input.action_release("aim_up")
	Input.action_press("aim_down", 1.0)
	for i in 2:
		await physics_frame
	check(absf(angle_difference(muzzle.rotation, PI / 2.0)) < 0.05, "right stick aims down")
	Input.action_release("aim_down")
	for i in 2:
		await physics_frame
	check(not reticle.visible, "reticle hides for mouse aim")

	# --- aim-driven facing and backwards walking -------------------------
	check(sprite.animation == "idle", "idle animation when standing still")
	Input.action_press("aim_right", 1.0)
	for i in 2:
		await physics_frame
	check(not sprite.flip_h, "aiming right faces the sprite right")
	Input.action_press("ui_left")
	for i in 8:
		await physics_frame
	check(player.motion.x < 0.0, "player can walk backwards while aiming right")
	check(not sprite.flip_h, "walking left does not flip the sprite")
	check(sprite.animation == "run", "running plays the run animation")
	var first_frame := sprite.frame
	var frame_changed := false
	for i in 30:
		await physics_frame
		if sprite.frame != first_frame:
			frame_changed = true
			break
	check(frame_changed, "run animation cycles its frames")
	Input.action_release("ui_left")
	Input.action_release("aim_right")

	Input.action_press("aim_left", 1.0)
	for i in 2:
		await physics_frame
	check(sprite.flip_h, "aiming left flips the sprite")
	Input.action_press("ui_right")
	for i in 8:
		await physics_frame
	check(player.motion.x > 0.0, "player can walk forwards while aiming left")
	check(sprite.flip_h, "walking right does not flip the sprite")
	Input.action_release("ui_right")
	Input.action_release("aim_left")
	for i in 2:
		await physics_frame
	check(sprite.animation == "idle", "idle returns after moving")

	Input.action_press("jump")
	for i in 3:
		await physics_frame
	Input.action_release("jump")
	check(player.motion.y < -300.0, "jump action triggers a jump")

	world.free()
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
