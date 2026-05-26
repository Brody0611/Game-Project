extends Node3D

func  _ready() -> void:
	$AnimationPlayer.play("open")

func _on_area_3d_body_entered(body: Node3D) -> void:
	$AnimationPlayer.play("close")
	$StaticBody3D/CollisionShape3D.disabled = false
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://lobby.tscn") 
