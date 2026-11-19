extends Area2D

const Sfx = preload("res://Scripts/Sfx.gd")

var door

func _ready():
	door = get_parent().find_child("Door")


func _process(delta):
	var bodies = get_overlapping_bodies()
	
	for body in bodies:
		if body.name == "Player":
			Sfx.play("key")
			door.open()
			queue_free()
