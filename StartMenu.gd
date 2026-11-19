extends Control

const Sfx = preload("res://Scripts/Sfx.gd")


func _ready() -> void:
	$CenterContainer/VBoxContainer/StartGame.grab_focus()


func _on_StartGame_pressed():
	Sfx.play("ui")
	global.time = 0
	global.deaths = 0
	global.totalTime = 10
	global.xPos = 0
	global.yPos = 0
	global.shake = 0.0
	global.weapon = 0
	get_tree().change_scene_to_file("res://World.tscn")

func _on_QuitGame_pressed():
	Sfx.play("ui")
	get_tree().quit()
