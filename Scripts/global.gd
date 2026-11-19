extends Node

var xPos = 0
var yPos = 0
var deaths = 0
var totalTime = (deaths + 1) * 10
var time = 0
var shake = 0.0
var weapon = 0

func add_shake(amount):
	shake = maxf(shake, amount)
