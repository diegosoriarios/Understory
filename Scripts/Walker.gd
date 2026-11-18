extends CharacterBody2D

@export var speed: int = 200

var velocity = Vector2()
var direction = 1
const UP = Vector2(0, -1)
var motion = Vector2()
var gravity = 10
var jump_force = -400
var acceleration = 50
var max_speed = 200
var hp = 3

func _ready():
	add_collision_exception_with(get_parent().find_child("Player"))


func _process(delta):
	if is_on_wall():
		direction *= -1
	
	motion.y += gravity
	var friction = false
	
	if direction < 0:
		motion.x = min(motion.x + acceleration, max_speed)
	else:
		motion.x = max(motion.x - acceleration, -max_speed)
	
	set_velocity(motion)
	set_up_direction(UP)
	move_and_slide()
	motion = velocity

func hit():
	hp -= 1
	if hp == 0:
		var file = "res://Assets/Sprites/Blood/" + str(int(randf_range(0, 43)))	 + ".png"
		var texture = load(file)
		var sprite = Sprite2D.new()
		sprite.set_texture(texture)
		sprite.position = position
		sprite.z_index = -3
		get_parent().add_child(sprite)
		queue_free()
