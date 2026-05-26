extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		$GPUParticles3D.emitting = true
		$Sprite3D.visible = false
		await get_tree().create_timer(2.31).timeout
		queue_free()
		print("playercollision")
		
