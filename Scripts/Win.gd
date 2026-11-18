extends Control

func _ready():
	$CenterContainer/VBoxContainer/Stats.text = "Time: %d s    Deaths: %d" % [int(global.time), global.deaths]

func _on_Menu_pressed():
	get_tree().change_scene_to_file("res://StartMenu.tscn")
