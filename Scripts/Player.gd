extends CharacterBody2D

const Sfx = preload("res://Scripts/Sfx.gd")
const UP = Vector2(0, -1)
const MAX_HP = 3
const COYOTE_TIME = 0.09
const JUMP_BUFFER_TIME = 0.1
const WALL_SLIDE_SPEED = 60.0
const WALL_JUMP_PUSH = 260.0
const WALL_JUMP_LOCK = 0.16
var motion = Vector2()
var speed = 200
var gravity = 10
var jump_force = -400
var acceleration = 50
var max_speed = 200
var jumps = 0
@export var next_level: String = ""
var gun = 1
var take_damage : set = set_take_damage
var frame = 0
var crouch = false
var stand
var stabbing = false
var is_jumping
var hp = MAX_HP
var coyote = 0.0
var jump_buffer = 0.0
var wall_lock = 0.0
var aim_dir := Vector2.RIGHT
var aim_from_pad := false
var gun_right := true
var last_mouse_screen := Vector2.ZERO

@onready var hud_hearts: Label = $HUD/Hearts
@onready var hud_time: Label = $HUD/Time
@onready var hud_deaths: Label = $HUD/Deaths
@onready var hud_toast: Label = $HUD/Toast

var Bullet = preload('res://Objects/Bullet.tscn')

func _process(delta):
	if hud_toast.modulate.a > 0.0:
		hud_toast.modulate.a = maxf(hud_toast.modulate.a - delta * 0.5, 0.0)
	
	if take_damage:
		frame += delta * 10
		$Sprite2D.visible = false if int(frame) % 2 == 0 else true
		if (int(frame) >= 10): on_timer_timeout()
	
	if stabbing:
		frame += delta * 10
		
		if (int(frame) > 3):
			$RayCast2D.enabled = false
			$RayCast2D.visible = false
			$AnimationPlayer.stop()
			frame = 0
			stabbing = false

func _physics_process(delta):
	motion.y += gravity
	var friction = false
	global.time += delta
	wall_lock = maxf(wall_lock - delta, 0.0)
	
	var wall_normal = Vector2.ZERO
	if global.wall_jump and is_on_wall() and not is_on_floor():
		wall_normal = get_wall_normal()
		var input_dir = Input.get_axis("ui_left", "ui_right")
		if input_dir * wall_normal.x < 0.0 and motion.y > WALL_SLIDE_SPEED:
			motion.y = WALL_SLIDE_SPEED
			_play_anim("jump")
	
	_update_aim()
	
	if crouch:
		$CollisionShape2D.scale.y = stand.y / 2
	else:
		$CollisionShape2D.scale.y = stand.y
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if Input.is_action_pressed("crouch"):
		crouch = true
	
	if Input.is_action_just_released("crouch"):
		crouch = false
	
	if Input.is_action_pressed("ui_right"):
		if wall_lock <= 0.0:
			motion.x = min(motion.x + acceleration, max_speed)
		if !is_jumping: _play_anim("run")
	elif Input.is_action_pressed("ui_left"):
		if wall_lock <= 0.0:
			motion.x = max(motion.x - acceleration, -max_speed)
	
		if !is_jumping: _play_anim("run")
	else:
		if !is_jumping: _play_anim("idle")
		friction = true
	
	if global.has_wings:
		if Input.is_action_pressed("jump"):
			motion.y = jump_force
	
	if is_on_floor():
		coyote = COYOTE_TIME
		is_jumping = false
		jumps = 0
		if friction == true and wall_lock <= 0.0:
			motion.x = lerp(motion.x, 0.0, 0.2)
	else:
		coyote -= delta
		if friction == true and wall_lock <= 0.0:
			motion.x = lerp(motion.x, 0.0, 0.05)
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME
	else:
		jump_buffer -= delta
	
	if jump_buffer > 0.0:
		if wall_normal != Vector2.ZERO and wall_lock <= 0.0:
			motion.y = jump_force
			motion.x = signf(wall_normal.x) * WALL_JUMP_PUSH
			jumps = 1
			is_jumping = true
			wall_lock = WALL_JUMP_LOCK
			jump_buffer = 0.0
			coyote = 0.0
			_play_anim("jump")
			Sfx.play("walljump")
		elif coyote > 0.0:
			_play_anim("jump")
			Sfx.play("jump")
			is_jumping = true
			motion.y = jump_force
			jumps = 1
			jump_buffer = 0.0
			coyote = 0.0
		elif jumps < 2 and global.double_jump_active == true and not is_on_floor():
			motion.y = jump_force
			is_jumping = true
			_play_anim("jump")
			Sfx.play("jump", 1.18)
			jumps += 1
			jump_buffer = 0.0
	
	velocity = motion
	up_direction = UP
	move_and_slide()
	motion = velocity
	
	if global.shake > 0.0:
		$Camera2D.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * global.shake
		global.shake = maxf(global.shake - delta * 30.0, 0.0)
		if global.shake == 0.0:
			$Camera2D.offset = Vector2.ZERO
	
	hud_time.text = "Time: %ds" % int(global.time)
	hud_deaths.text = "Deaths: %d" % global.deaths
	


func _ready():
	_play_anim("idle")
	var initPos = get_parent().find_child("initPos")
	if initPos != null:
		position = initPos.position
	if global.xPos != 0 and global.yPos != 0:
		motion.x = global.xPos
		motion.y = global.yPos
		get_node(".").motion.x = global.xPos
		get_node(".").motion.y = global.yPos
		
	velocity = motion
	up_direction = UP
	move_and_slide()
	motion = velocity
	
	stand = $CollisionShape2D.scale
	update_hud()
	setup_camera_limits()

func setup_camera_limits():
	var tilemap = get_parent().find_child("TileMap")
	if tilemap is TileMapLayer and tilemap.tile_set != null:
		var rect = tilemap.get_used_rect()
		var ts = tilemap.tile_set.tile_size
		var cam = $Camera2D
		cam.limit_left = rect.position.x * ts.x
		cam.limit_top = rect.position.y * ts.y - 200
		cam.limit_right = (rect.position.x + rect.size.x) * ts.x
		cam.limit_bottom = (rect.position.y + rect.size.y) * ts.y

func _play_anim(anim: String) -> void:
	if $Sprite2D.animation != anim or not $Sprite2D.is_playing():
		$Sprite2D.play(anim)

func _update_aim() -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.3)
	var mouse_screen := get_viewport().get_mouse_position()
	var mouse_moved := mouse_screen.distance_to(last_mouse_screen) > 0.5
	last_mouse_screen = mouse_screen
	var pad_active := stick.length() > 0.3
	if pad_active:
		aim_dir = stick.normalized()
		aim_from_pad = true
	elif aim_from_pad and not mouse_moved:
		pass
	else:
		aim_from_pad = false
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 2.0:
			aim_dir = to_mouse.normalized()
	if absf(aim_dir.x) > 0.12:
		gun_right = aim_dir.x > 0.0
	$Sprite2D.flip_h = not gun_right
	$Muzzle.rotation = aim_dir.angle()
	$Muzzle.position.x = 18.0 if gun_right else -18.0
	$Muzzle/icon.flip_v = not gun_right
	$Muzzle/icon.flip_h = false
	$RayCast2D.rotation = 0.0 if gun_right else PI
	$RayCast2D/Weapon.flip_h = not gun_right
	var reticle := get_node_or_null("Reticle") as Sprite2D
	if reticle:
		reticle.visible = pad_active
		if pad_active:
			reticle.global_position = global_position + aim_dir * 110.0


func shoot():
	if gun == 0:
		Sfx.play("walljump", 1.4)
		stabbing = true
		$RayCast2D.enabled = true
		$RayCast2D.visible = true
		
		$AnimationPlayer.play("Attack")
		
		var coll = $RayCast2D.get_collider()
		check_colision(coll)
	elif gun == 1:
		Sfx.play("shoot")
		var bullet = Bullet.instantiate()
		bullet.start($Muzzle.global_position, $Muzzle.rotation, self)
		get_parent().add_child(bullet)
	elif gun == 2:
		Sfx.play("shoot", 0.92)
		var bullet1 = Bullet.instantiate()
		var bullet2 = Bullet.instantiate()
		var bullet3 = Bullet.instantiate()
		bullet1.start($Muzzle.global_position, $Muzzle.rotation, self)
		bullet2.start($Muzzle.global_position, $Muzzle.rotation + deg_to_rad(15), self)
		bullet3.start($Muzzle.global_position, $Muzzle.rotation - deg_to_rad(15), self)
		get_parent().add_child(bullet1)
		get_parent().add_child(bullet2)
		get_parent().add_child(bullet3)

func on_timer_timeout():
	$Sprite2D.visible = true
	frame = 0
	set_take_damage(false)

func set_take_damage(new_value):
	if new_value and not take_damage and hp > 0:
		hp -= 1
		Sfx.play("hurt")
		global.add_shake(3.0)
		update_hud()
		if hp <= 0:
			die()
			return
	take_damage = new_value

func hit():
	set_take_damage(true)

func die():
	global.deaths += 1
	Sfx.play("death")
	global.add_shake(8.0)
	get_tree().reload_current_scene()

func show_toast(text):
	hud_toast.text = text
	hud_toast.modulate.a = 1.0

func update_hud():
	if hud_hearts == null:
		return
	var filled = max(hp, 0)
	hud_hearts.text = "♥".repeat(filled) + "♡".repeat(MAX_HP - filled)

func check_colision(coll):
	if $RayCast2D.is_colliding() and coll.is_in_group("enemy"):
		coll.hit()
