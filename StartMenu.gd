extends Control


func _on_StartGame_pressed():
	global.time = 0
	global.deaths = 0
	global.totalTime = 10
	global.xPos = 0
	global.yPos = 0
	global.shake = 0.0
	get_tree().change_scene_to_file("res://World.tscn")

func _on_QuitGame_pressed():
	get_tree().quit()
