extends Area2D

const Sfx = preload("res://Scripts/Sfx.gd")

const KIND_IDS = {"normal": 0, "machine": 1, "spread": 2}
const LETTERS = {0: "N", 1: "M", 2: "S"}
const TINTS = {
	0: Color(0.85, 0.9, 1.0, 0.9),
	1: Color(1.0, 0.55, 0.25, 0.9),
	2: Color(0.45, 0.85, 1.0, 0.9),
}

@export_enum("normal", "machine", "spread") var kind: String = "normal"

var t = 0.0

func _ready() -> void:
	var id = _kind_id()
	$Letter.text = LETTERS[id]
	$Sprite2D.modulate = TINTS[id]

func _kind_id() -> int:
	return KIND_IDS.get(kind, 0)

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
	player.pick_weapon(_kind_id())
	queue_free()
