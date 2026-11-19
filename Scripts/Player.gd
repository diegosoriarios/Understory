extends CharacterBody2D

const Sfx = preload("res://Scripts/Sfx.gd")
const UP = Vector2(0, -1)
const MAX_HP = 3
const COYOTE_TIME = 0.09
const JUMP_BUFFER_TIME = 0.1
const WEAPON_NORMAL = 0
const WEAPON_MACHINE = 1
const WEAPON_SPREAD = 2
const FIRE_RATE = {WEAPON_NORMAL: 0.28, WEAPON_MACHINE: 0.09, WEAPON_SPREAD: 0.34}
const WEAPON_LETTER = {WEAPON_NORMAL: "N", WEAPON_MACHINE: "M", WEAPON_SPREAD: "S"}
const WEAPON_TOAST = {
	WEAPON_NORMAL: "Normal gun",
	WEAPON_MACHINE: "Machine gun! Hold fire!",
	WEAPON_SPREAD: "Spread gun! Hold fire!",
}
var motion = Vector2()
var speed = 200
var gravity = 10
var jump_force = -400
var acceleration = 50
var max_speed = 200
@export var next_level: String = ""
var weapon = WEAPON_NORMAL
var fire_cd = 0.0
var take_damage : set = set_take_damage
var frame = 0
var crouch = false
var stand
var is_jumping
var hp = MAX_HP
var coyote = 0.0
var jump_buffer = 0.0
var aim_dir := Vector2.RIGHT
var aim_from_pad := false
var gun_right := true
var last_mouse_screen := Vector2.ZERO

@onready var hud_hearts: Label = $HUD/Hearts
@onready var hud_time: Label = $HUD/Time
@onready var hud_deaths: Label = $HUD/Deaths
@onready var hud_toast: Label = $HUD/Toast
@onready var hud_weapon: Label = $HUD/Weapon

var Bullet = preload('res://Objects/Bullet.tscn')

func _process(delta):
	if hud_toast.modulate.a > 0.0:
		hud_toast.modulate.a = maxf(hud_toast.modulate.a - delta * 0.5, 0.0)
	
	if take_damage:
		frame += delta * 10
		$Sprite2D.visible = false if int(frame) % 2 == 0 else true
		if (int(frame) >= 10): on_timer_timeout()

func _physics_process(delta):
	motion.y += gravity
	var friction = false
	global.time += delta
	fire_cd = maxf(fire_cd - delta, 0.0)
	
	_update_aim()
	
	if crouch:
		$CollisionShape2D.scale.y = stand.y / 2
	else:
		$CollisionShape2D.scale.y = stand.y
	
	if Input.is_action_pressed("shoot") and fire_cd <= 0.0:
		shoot()
		fire_cd = FIRE_RATE[weapon]
	
	if Input.is_action_pressed("crouch"):
		crouch = true
	
	if Input.is_action_just_released("crouch"):
		crouch = false
	
	if Input.is_action_pressed("ui_right"):
		motion.x = min(motion.x + acceleration, max_speed)
		if !is_jumping: _play_anim("run")
	elif Input.is_action_pressed("ui_left"):
		motion.x = max(motion.x - acceleration, -max_speed)
		if !is_jumping: _play_anim("run")
	else:
		if !is_jumping: _play_anim("idle")
		friction = true
	
	if is_on_floor():
		coyote = COYOTE_TIME
		is_jumping = false
		if friction == true:
			motion.x = lerp(motion.x, 0.0, 0.2)
	else:
		coyote -= delta
		if friction == true:
			motion.x = lerp(motion.x, 0.0, 0.05)
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME
	else:
		jump_buffer -= delta
	
	if jump_buffer > 0.0 and coyote > 0.0:
		_play_anim("jump")
		Sfx.play("jump")
		is_jumping = true
		motion.y = jump_force
		jump_buffer = 0.0
		coyote = 0.0
	
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
		
	velocity = motion
	up_direction = UP
	move_and_slide()
	motion = velocity
	
	stand = $CollisionShape2D.scale
	weapon = global.weapon
	hud_weapon.text = WEAPON_LETTER[weapon]
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
	var reticle := get_node_or_null("Reticle") as Sprite2D
	if reticle:
		reticle.visible = pad_active
		if pad_active:
			reticle.global_position = global_position + aim_dir * 110.0


func _spawn_bullet(angle: float):
	var bullet = Bullet.instantiate()
	bullet.start($Muzzle.global_position, angle, self)
	get_parent().add_child(bullet)

func shoot():
	if weapon == WEAPON_SPREAD:
		Sfx.play("shoot", 0.92)
		_spawn_bullet($Muzzle.rotation)
		_spawn_bullet($Muzzle.rotation + deg_to_rad(15))
		_spawn_bullet($Muzzle.rotation - deg_to_rad(15))
	else:
		Sfx.play("shoot", 1.25 if weapon == WEAPON_MACHINE else 1.0)
		_spawn_bullet($Muzzle.rotation)

func pick_weapon(kind: int):
	weapon = kind
	global.weapon = kind
	hud_weapon.text = WEAPON_LETTER[weapon]
	fire_cd = 0.0
	show_toast(WEAPON_TOAST[kind])

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
	global.weapon = WEAPON_NORMAL
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
