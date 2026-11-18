extends Node2D

const TILE := 32
const SURFACE_ROWS := 40
const SHEET_W := 702

var region_x := 0.0
var flow := 0.0


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	region_x = fposmod(position.x - TILE * 0.5, SHEET_W)
	_apply_region()


func _apply_region():
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		var offset := int(fposmod(region_x + floor(flow), SHEET_W - TILE))
		sprite.region_rect = Rect2(offset, 15, TILE, SURFACE_ROWS)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	flow += delta * 12.0
	_apply_region()

	var areas = $Area2D.get_overlapping_bodies()
	
	for area in areas:
		if area.name == "Player" and area.has_method("set_take_damage"):
			area.set_take_damage(true)
