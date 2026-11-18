extends Area2D

const Sfx = preload("res://Scripts/Sfx.gd")

const TOASTS = {
	"double_jump": "Double jump unlocked! Jump again in the air.",
	"wall_jump": "Wall jump unlocked! Jump while sliding on a wall.",
}
const FLAGS = {
	"double_jump": "double_jump_active",
	"wall_jump": "wall_jump",
}

@export_enum("double_jump", "wall_jump") var upgrade: String = "double_jump"

var t = 0.0

func _process(delta):
	t += delta * 3.0
	$Sprite2D.scale = Vector2.ONE * (0.09 + sin(t) * 0.015)
	$Sprite2D.modulate.a = 0.8 + sin(t) * 0.15
	rotation = sin(t * 0.5) * 0.08
	
	for body in get_overlapping_bodies():
		if body.name == "Player":
			grant(body)
			return

func grant(player):
	Sfx.play("pickup")
	global.set(FLAGS.get(upgrade, upgrade), true)
	if player.has_method("show_toast"):
		player.show_toast(TOASTS.get(upgrade, "Upgrade unlocked!"))
	queue_free()
