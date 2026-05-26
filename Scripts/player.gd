extends CharacterBody3D

class_name Player

@export var look_sensitivity : float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 8.5
@export var bottle_item: Item

@export var acceleration := 10.0
@export var sprint_acceleration := 10.0
@export var deceleration := 12.0

var bottle_scn = "res://throw_bottle.tscn"
var holding := true
var stamina := 100
var money := 0
var current_speed := 0.0
var tweening := false
var viewing := false
var can_toggle_camera := true

@onready var ray = $Head/Camera3D/RayCast3D

const HEADBOB_MOVE_AMMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

var held_bottle: RigidBody3D = null
var wish_dir := Vector3.ZERO

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _unhandled_input(event: InputEvent) -> void:

	if is_hiding:
		return

	if viewing:
		return
	
	if camera_locked:
		return
	
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			camera.rotate_x(-event.relative.y * look_sensitivity)
			camera.rotation.x = clamp(
				camera.rotation.x,
				deg_to_rad(-90),
				deg_to_rad(90)
			)

func headbob_effect(delta):

	# ADD THIS
	if viewing:
		return

	headbob_time += delta * self.velocity.length()

	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMMOUNT,
		0
	)

func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

func _handle_ground_physics(delta) -> void:
	var target_speed = get_move_speed()
	
	# Choose accel based on whether we're speeding up or slowing down
	var accel = acceleration
	if current_speed > target_speed:
		accel = deceleration
	elif target_speed == sprint_speed:
		accel = sprint_acceleration
	
	# Smoothly move toward target speed
	current_speed = move_toward(current_speed, target_speed, accel * delta)
	
	# Apply movement
	self.velocity.x = wish_dir.x * current_speed
	self.velocity.z = wish_dir.z * current_speed

	headbob_effect(delta)

func get_interactable_component_at_shapecast() -> InteractableComponent:
	for i in %InteractShapeCast.get_collision_count():
		if i > 0 and %InteractShapeCast.get_collider(0) != $".":
			return null
		if %InteractShapeCast.get_collider(i) == null:
			print("it null")
			return null
		if %InteractShapeCast.get_collider(i).get_node_or_null("InteractableComponent") is InteractableComponent:
			return %InteractShapeCast.get_collider(i).get_node_or_null("InteractableComponent")
	return null

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	var text_shown = "Money: %d" % money
	$Head/Camera3D/Label3D.text = text_shown
	
	if viewing == true:
		$Head/Camera3D/Sprite3D.visible = false
		$ShopMenu.visible = true
	elif viewing == false:
		$ShopMenu.visible = false
	if camera_locked:
		move_and_slide()
		return
	
	if !tweening:
		if get_interactable_component_at_shapecast():
			get_interactable_component_at_shapecast().hover_curser(self)

			if Input.is_action_just_released("interact"):
				get_interactable_component_at_shapecast().interact_with()
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	if is_hiding:
		move_and_slide()
		return
	
	move_and_slide()
	
	#Stamina
	#print(stamina)
	if stamina > 100:
		stamina = 100
	if get_move_speed() == sprint_speed:
		stamina -= 1
	elif get_move_speed() != sprint_speed:
		stamina += 1


func emit_sound(pos: Vector3, loudness: float):
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for e in enemies:
		if e.has_method("hear_sound"):
			e.hear_sound(pos, loudness)

func _input(event):
	if event.is_action_pressed("ui_accept"): # usually SPACE or ENTER
		print("Sound emitted!")
		emit_sound(global_position, 10.0)
		
		if event.is_action_pressed("attack"):
			throw_bottle()

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
	

@export var max_slots := 3

var inventory: Array = []
var selected_slot := 0

func add_item(item):
	if inventory.size() >= max_slots:
		print("Inventory full")
		return false
	print("Inventory now:", inventory.size())
	
	inventory.append(item)
	print("Picked up:", item.item_name)
	return true

func remove_item(index: int):
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)

func get_current_item():
	if inventory.is_empty():
		return null
	return inventory[selected_slot]

func get_looked_at_object():
	if ray.is_colliding():
		return ray.get_collider()
	return null

var is_hiding = false
var saved_transform

func enter_hiding(target_transform: Transform3D):
	is_hiding = true
	
	# Save position
	saved_transform = global_transform
	
	# Move player into locker
	global_transform = target_transform
	
	# Disable movement
	velocity = Vector3.ZERO
	
	# Optional: disable collision
	$CollisionShape3D.disabled = true
	
	# Optional: lock camera
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func exit_hiding():
	is_hiding = false
	
	# Restore position (or move slightly outside locker)
	global_position += -global_transform.basis.z * 1.5
	
	$CollisionShape3D.disabled = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

@onready var head = $Head
@onready var camera = $Head/Camera3D

var camera_locked := false

var saved_head_transform : Transform3D

func toggle_camera(target_pos: Vector3, look_at_pos: Vector3, duration := 1.0):

	if !can_toggle_camera or camera_locked:
		return

	can_toggle_camera = false
	camera_locked = true

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	if !viewing:

		viewing = true

		saved_head_transform = head.global_transform

		var target := Transform3D.IDENTITY
		target.origin = target_pos
		target = target.looking_at(look_at_pos, Vector3.UP)

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$"../StaticBody3D3/MeshInstance3D".visible = false

		tween.tween_property(
			head,
			"global_transform",
			target,
			duration
		)

	else:

		viewing = false

		$Head/Camera3D/Sprite3D.visible = false

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		tween.tween_property(
			head,
			"global_transform",
			saved_head_transform,
			duration
		)

	tween.finished.connect(func():
		camera_locked = false
		
		await get_tree().create_timer(0.25).timeout
		can_toggle_camera = true
	)

	get_interactable_component_at_shapecast().interact_with()
