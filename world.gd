extends Node3D

var holding := true
const bottle_scn = preload("res://throw_bottle.tscn")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		throw()

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
