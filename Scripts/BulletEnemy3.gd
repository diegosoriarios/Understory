extends CharacterBody2D

var speed = 500

func start(pos, dir, ignore):
	rotation = dir
	add_collision_exception_with(ignore)
	position = pos
	velocity = Vector2(speed, 0).rotated(rotation)

var life = 4.0

func _physics_process(delta):
	life -= delta
	if life <= 0.0:
		queue_free()
		return
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
