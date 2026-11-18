extends Control

const Sfx = preload("res://Scripts/Sfx.gd")

func _ready():
	Sfx.play("win")
	$CenterContainer/VBoxContainer/Stats.text = "Time: %d s    Deaths: %d" % [int(global.time), global.deaths]

func _on_Menu_pressed():
	get_tree().change_scene_to_file("res://StartMenu.tscn")
