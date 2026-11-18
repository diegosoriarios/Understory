extends CharacterBody2D

var direction = 0
@export var bullets = 16
var speed = 200
var timer
var allow_attack = true

var run_speed = 25
var player
var hp = 50
var Bullet = preload('res://Objects/BulletEnemy.tscn')
const BulletKey = preload("res://Objects/Chave.tscn")

func _ready():
	player = get_parent().get_node("Player")
	velocity = position.direction_to(player.position) * speed
	
func _process(delta):
	$Area2D.look_at(player.get_position())
	
	velocity = Vector2.ZERO
	if player:
		velocity = position.direction_to(player.position) * run_speed
	move_and_slide()
	
	var bodies = $Area2D.get_overlapping_bodies()
	
	for body in bodies:
		if body.name == "Player":
			body.set_take_damage(true)
	
	if allow_attack:
		shoot()
		allow_attack = false
		timer = Timer.new()
		timer.wait_time = 1.0
		timer.timeout.connect(on_timer_timeout)
		add_child(timer)
		timer.start()

func hit():
	hp -= 1
	
	if hp == 25:
		bullets = 24
		run_speed = 40
	elif hp == 0:
		var key = BulletKey.instantiate()
		key.position = position
		get_parent().add_child(key)
		queue_free()

func shoot():
	var deg = 360/bullets
	for i in range(bullets):
		var bullet = Bullet.instantiate()
		bullet.start(self.position, $Area2D.rotation - deg_to_rad(deg * i), self)
		get_parent().add_child(bullet)

func on_timer_timeout():
	allow_attack = true

