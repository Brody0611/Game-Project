extends Node3D

var in_shop : bool = false
var open : bool = true
var holding := true
const bottle_scn = preload("res://throw_bottle.tscn")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		$Elevator/AnimationPlayer.play("close")
		$StaticBody3D2/CollisionShape3D.disabled = false
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://world.tscn") 
	

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		throw()
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


func pressed() -> void:
	pass # Replace with function body.

func throw():
	if holding == false:
		return null
	var direction = -$player/Head/Camera3D.global_transform.basis.z.normalized() + Vector3(0,.4,0)
	var new_bottle = bottle_scn.instantiate()
	add_child(new_bottle)
	new_bottle.rotation = Vector3(randf(),randf(),randf())
	new_bottle.global_position = $player/Head/BottleSpawn.global_position
	new_bottle.gravity_scale = 2
	new_bottle.apply_central_impulse(direction * 17)
	print("trow")
