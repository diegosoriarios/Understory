extends CharacterBody2D

const UP = Vector2(0, -1)
const GRAVITY = 600.0
const LAUNCH_SPEED = 260.0
const HORIZONTAL_SPEED = 120.0

var motion = Vector2.ZERO
var spin = 0.0
var life = 4.0

func start(pos):
	randomize()
	position = pos
	var drift = randf_range(-1.0, 1.0)
	motion = Vector2(drift * HORIZONTAL_SPEED, -LAUNCH_SPEED)
	spin = randf_range(6.0, 10.0) * (1.0 if drift >= 0.0 else -1.0)
	rotation = 0.0

func _physics_process(delta):
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	motion.y += GRAVITY * delta
	rotation += spin * delta
	velocity = motion
	up_direction = UP
	move_and_slide()
	motion = velocity
	
	for body in $Area2D.get_overlapping_bodies():
		if body.name == "TileMap":
			queue_free()
		elif body.name == "Player":
			body.set_take_damage(true)
			queue_free()
