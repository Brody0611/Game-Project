extends RigidBody3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("wall"):
		$Area3D/CollisionShape3D.disabled = true
		$Bottle.visible = false
		$GPUParticles3D.emitting = true
		$AudioStreamPlayer3D.play()
		$AudioStreamPlayer3D2.play()
