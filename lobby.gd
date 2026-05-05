extends Node3D

var open : bool = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	$Elevator/AnimationPlayer.play("close")
	$StaticBody3D2/CollisionShape3D.disabled = false
	print("i didi ir")
	

func _physics_process(delta: float) -> void:
	if open == false:
		$Elevator/AnimationPlayer.play("close")
		$StaticBody3D2/CollisionShape3D.disabled = false
	else:
		open = true
