extends Area2D

var hp = int(randf_range(3, 5))

func _ready():
	randomize()

func _process(delta):
	if hp == 0:
		queue_free()

func hit():
	hp -= 1
	$Sprite2D.frame += 1
