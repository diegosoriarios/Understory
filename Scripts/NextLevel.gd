extends Area2D

@export var target_scene: String = ""

var next_level = [
	"res://Levels/" + '1' + ".tscn",
	"res://Levels/" + '2' + ".tscn"
]

func _physics_process(delta):
	var bodies = get_overlapping_bodies()
	
	for body in bodies:
		if body.name == "Player":
			global.double_jump_active = !global.double_jump_active
			if target_scene != "":
				get_tree().change_scene_to_file(target_scene)
				return
			next_level.shuffle()
			var first = next_level.front()
			#var level = first.instance()
			get_tree().change_scene_to_file(first)
