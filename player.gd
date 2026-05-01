extends CharacterBody3D

@export var look_sensitivity : float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 8.5

const HEADBOB_MOVE_AMMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

var held_bottle: RigidBody3D = null
var wish_dir := Vector3.ZERO

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMMOUNT,
		0
	)

func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

func _handle_ground_physics(delta) -> void:
	self.velocity.x = wish_dir.x * get_move_speed()
	self.velocity.z = wish_dir.z * get_move_speed()

	headbob_effect(delta)

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()

func emit_sound(pos: Vector3, loudness: float):
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for e in enemies:
		if e.has_method("hear_sound"):
			e.hear_sound(pos, loudness)

func _input(event):
	if event.is_action_pressed("ui_accept"): # usually SPACE or ENTER
		print("Sound emitted!")
		emit_sound(global_position, 10.0)
	
		if event.is_action_pressed("interact"):
			try_pickup()
		
		if event.is_action_pressed("attack"):
			throw_bottle()

func try_pickup():
	var space = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + -transform.basis.z * 3.0
	)
	
	var result = space.intersect_ray(query)
	
	if result and result.collider is RigidBody3D:
		var body = result.collider
		
		if body.name.contains("Bottle"):
			held_bottle = body
			body.freeze = true
			
			body.get_parent().remove_child(body)
			add_child(body)
			
			body.transform.origin = Vector3(0, 1.5, -1)

func throw_bottle():
	if held_bottle == null:
		return
	
	var bottle = held_bottle
	held_bottle = null
	
	remove_child(bottle)
	get_parent().add_child(bottle)
	
	bottle.global_position = global_position + -transform.basis.z * 1.5
	bottle.freeze = false
	
	var force = -transform.basis.z * 15.0
	bottle.apply_impulse(Vector3.ZERO, force)
	
