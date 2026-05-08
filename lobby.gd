extends Node3D

var in_shop : bool = false
var open : bool = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		$Elevator/AnimationPlayer.play("close")
		$StaticBody3D2/CollisionShape3D.disabled = false
		print("i didi ir")
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://world.tscn") 
	

func _physics_process(delta: float) -> void:
	if open == false:
		$Elevator/AnimationPlayer.play("close")
		$StaticBody3D2/CollisionShape3D.disabled = false
	else:
		open = true

func _process(delta: float) -> void:
	if $StaticBody3D3.open == true:
		$player.toggle_camera(Vector3(4, 3, 0),Vector3(6, 3, 0),.5)
		$Collisions/CollisionShape3D4.disabled = true
	else:
		$Collisions/CollisionShape3D4.disabled = false
