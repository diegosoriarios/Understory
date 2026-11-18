extends ParallaxBackground

## Positions the backdrop layers so their ground band sits on the level floor and
## tiles each forest layer sideways with alternating mirrored copies.

@export var ground_y := 448.0

const TILE_WIDTH := 384
const COPIES := 6


func _ready() -> void:
	for layer in get_children():
		var sprite := layer.get_node_or_null("Sprite") as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var height := sprite.texture.get_height() * sprite.scale.y
		sprite.position.y = ground_y - height
		if layer.name == "Sky":
			continue
		sprite.position.x = -TILE_WIDTH
		sprite.flip_h = true
		for i in range(1, COPIES):
			var copy := sprite.duplicate() as Sprite2D
			copy.position.x = -TILE_WIDTH + i * TILE_WIDTH
			copy.flip_h = i % 2 == 0
			layer.add_child(copy)
