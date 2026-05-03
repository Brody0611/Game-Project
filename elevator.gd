extends Node3D

func _ready() -> void:
	await get_tree().create_timer(0.8).timeout
	$AnimationPlayer.play("open")
