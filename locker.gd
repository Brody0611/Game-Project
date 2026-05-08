extends Node3D

@onready var hide_pos = $HidePosition

var occupied := false

func interact(player):
	if occupied:
		player.exit_hiding()
		occupied = false
	else:
		player.enter_hiding(hide_pos.global_transform)
		occupied = true
