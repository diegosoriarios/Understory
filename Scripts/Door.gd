extends StaticBody2D

const Sfx = preload("res://Scripts/Sfx.gd")

var is_opened = false

func _ready():
	pass # Replace with function body.

#func _process(delta):
#	pass

func open():
	Sfx.play("door")
	$CollisionShape2D.scale = Vector2.ZERO
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
