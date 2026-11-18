extends CharacterBody2D

var Bullet = preload('res://Objects/BulletEnemy2.tscn')
var timer
var allow_attack = true
var direction = 0
@export var bullets = 3
var frame = 0
var player

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 2
	timer.timeout.connect(on_timer_timeout)
	add_child(timer)
	
func _process(delta):
	player = get_parent().get_node("Player").get_position()
	if player.x < self.position.x:
		direction = 1
	else:
		direction = 0
	
	if allow_attack:
		shoot()
		allow_attack = false
		
		timer.start()

func shoot():
	var deg = 15/bullets
	if bullets == 1:
		var bullet = Bullet.instantiate()
		bullet.start(self.position)
		get_parent().add_child(bullet)
	else:
		for i in range(bullets):
			var bullet = Bullet.instantiate()
			bullet.start(self.position)
			get_parent().add_child(bullet)

func on_timer_timeout():
	allow_attack = true


func hit():
	pass
