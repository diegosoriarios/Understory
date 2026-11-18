extends Area2D

const Sfx = preload("res://Scripts/Sfx.gd")

var speed = 50
var frame = 0
var direction = 1
var v_max = randf_range(20, 40)
var hp = 1
var Blood = preload("res://Objects/Blood.tscn")
var Explosion = preload("res://Objects/Effects/Explosion.tscn")

func _ready():
	pass # Replace with function body.
	
func _process(delta):
	frame += delta * 10
	if int(frame) % int(v_max) == 0 and int(frame) != 0:
		frame = 0
		direction *= -1
	self.position.x -= 1 * delta * speed
	self.position.y -= 1 * delta * speed * direction
	
	var bodies = get_overlapping_bodies()
	
	for body in bodies:
		if body.name == "Player":
			body.set_take_damage(true)

func hit():
	Sfx.play("hit")
	hp -= 1
	if hp == 0:
		var file = "res://Assets/Sprites/Blood/" + str(int(randf_range(1, 43)))	 + ".png"
		var texture = load(file)
		var sprite = Sprite2D.new()
		sprite.set_texture(texture)
		sprite.position = position
		sprite.z_index = -3
		get_parent().add_child(sprite)
		
		var blood = Blood.instantiate()
		blood.global_position = global_position
		
		get_parent().add_child(blood)
		
		var explosion = Explosion.instantiate()
		explosion.scale = scale
		explosion.change_texture($icon.get_texture())
		explosion.global_position = global_position
		get_parent().add_child(explosion)
		explosion.active()
		
		#$Explosion.active()
		
		Sfx.play("explosion")
		queue_free()
