extends CharacterBody2D

const Sfx = preload("res://Scripts/Sfx.gd")

var Bullet = preload('res://Objects/BulletEnemy.tscn')
var timer
var allow_attack = true
var direction = 0
@export var bullets = 1
var hp = int(randf_range(15, 20))

func _ready():
	randomize()
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1
	timer.timeout.connect(on_timer_timeout)
	add_child(timer)
	
func _process(delta):
	var player = get_parent().get_node("Player").get_position()
	if player.y < self.position.y:
		direction = 1
	else:
		direction = 3
	
	if player.x > position.x:
		position.x += 2
	elif player.x < position.x:
		position.x -= 2
	
	if allow_attack:
		shoot()
		allow_attack = false
		
		timer.start()

func shoot():
	var deg = 15/bullets
	if bullets == 1:
		var bullet = Bullet.instantiate()
		bullet.start(self.position, deg_to_rad(-90 * direction), self)
		get_parent().add_child(bullet)
	else:
		for i in range(bullets):
			var bullet = Bullet.instantiate()
			var index = (90 * direction) + (deg * (i - 1))
			bullet.start(self.position, deg_to_rad(index), self)
			get_parent().add_child(bullet)

func on_timer_timeout():
	allow_attack = true

func hit():
	Sfx.play("hit")
	hp -= 1
	if hp == 0:
		Sfx.play("explosion")
		queue_free()
