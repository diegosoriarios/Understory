extends CharacterBody2D

var speed = 500

const UP = Vector2(0, -1)
var motion = Vector2()
var gravity = 10
var jump_force = -400
var acceleration = 50
var max_speed = 200
var jumps = 0
var frame = 0
var target
var random

func start(pos):
	randomize()
	position = pos
	random = Vector2(randf_range(-5, 5), 0)
	target = position + random
	gravity = -10
	rotation = deg_to_rad(-90)

var life = 4.0

func _physics_process(delta):
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	motion.y += gravity
	gravity += .35
	var friction = false
	if random.x > 0:
		if rotation < 90:
			rotation += deg_to_rad(2)
		if position.x < target.x:
			motion.x += 8
	else:
		if rotation < 270:
			rotation -= deg_to_rad(2)
		if position.x > target.x:
			motion.x -= 8
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		if collision.get_collider().has_method("hit"):
			collision.get_collider().hit()
	
	var bodies = $Area2D.get_overlapping_bodies()
	
	for body in bodies:
		if body.name == "TileMap":
			queue_free()
		if body.name == "Player":
			body.set_take_damage(true)
			queue_free()
	
	velocity = motion
	up_direction = UP
	move_and_slide()
	motion = velocity
