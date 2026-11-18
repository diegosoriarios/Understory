extends CharacterBody2D

const Sfx = preload("res://Scripts/Sfx.gd")

var Bullet = preload('res://Objects/BulletEnemy.tscn')
var timer
var allow_attack = true
@export var bullets = 4
var frame = 0
var forma = 1
var hp = 50
var motion = Vector2()
const UP = Vector2.ZERO
var gravity = 10
var yPos

func _ready():
	yPos = position.y
	
func _process(delta):
	var player = get_parent().get_node("Player")
	$Area2D.look_at(player.get_position())
	position.y = yPos
	
	for body in $Area2D.get_overlapping_bodies():
		if body.name == "Player" and body.has_method("set_take_damage"):
			body.set_take_damage(true)
	
	frame += delta * 10
	
	if int(frame) % 10 == 0 and int(frame) != 0:
		allow_attack = true
	
	if forma == 2:
		if player.get_position().x > position.x:
			motion.x += gravity
		else:
			motion.x -= gravity
		velocity = motion
		up_direction = UP
		move_and_slide()
		motion = velocity
	elif forma == 3:
		$Area2D.rotate(.5)
		
	if allow_attack:
		shoot()
		allow_attack = false
		frame = 0

func shoot():
	if forma == 3:
		for i in 10:
			var bullet = Bullet.instantiate()
			bullet.start(self.position, $Area2D.rotation - deg_to_rad(i * 15), self, 150)
			get_parent().add_child(bullet)
	else:
		var deg = 360/bullets
		for i in range(bullets):
			var bullet = Bullet.instantiate()
			bullet.start(self.position, $Area2D.rotation - deg_to_rad(deg * i), self)
			get_parent().add_child(bullet)

const BulletKey = preload("res://Objects/Chave.tscn")

func hit():
	Sfx.play("bosshit")
	hp -= 1
	
	if hp == 30:
		forma = 2
	elif hp == 15:
		forma = 3
	elif hp == 0:
		global.add_shake(10.0)
		var key = BulletKey.instantiate()
		key.position = position
		get_parent().add_child(key)
		Sfx.play("explosion")
		queue_free()
