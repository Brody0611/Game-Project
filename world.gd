extends Node3D

var holding := true

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("gen"):
		throw()

func throw():
	if holding == false:
		return null
	var direction = -$player/Head/Camera3D.global_transform.basis.z.normalized()
	$ThrowBottle.global_position = Vector3($player.global_position.x,$player.global_position.y + 2, $player.global_position.z)
	$ThrowBottle.gravity_scale = 1
	$ThrowBottle.apply_central_impulse(direction * 13)
	print("trow")
