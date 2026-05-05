extends Node3D

func  _ready() -> void:
	$AnimationPlayer.play("open")

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("kgrskh")
	$AnimationPlayer.play("close")
	$StaticBody3D/CollisionShape3D.disabled = false
