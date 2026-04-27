extends Node3D

@export var start_room: PackedScene
@export var end_room: PackedScene
@export var main_rooms: Array[PackedScene]
@export var branch_rooms: Array[PackedScene]

@export var main_length := 6
@export var branch_count := 4

var rng := RandomNumberGenerator.new()

var placed_rooms = []
var open_doors = []

func _ready():
	rng.randomize()

	var start = spawn_room(start_room, Vector3.ZERO, 0)
	placed_rooms.append(start)

	open_doors += get_doors(start)

	generate_main_path(start)
	generate_branches()

func generate_main_path(current_room):
	var last_room = current_room

	for i in range(main_length):
		var next_scene = main_rooms.pick_random()
		var result = attach_room(last_room, next_scene)

		if result == null:
			continue

		placed_rooms.append(result.room)
		last_room = result.room

	# Place end room
	var end = attach_room(last_room, end_room)
	if end:
		placed_rooms.append(end.room)

func generate_branches():
	for i in range(branch_count):
		if open_doors.is_empty():
			return

		var door = open_doors.pick_random()
		var room_scene = branch_rooms.pick_random()

		var result = attach_room_to_door(door, room_scene)

		if result:
			placed_rooms.append(result.room)

func attach_room(from_room, new_scene):
	var from_doors = get_doors(from_room)
	from_doors.shuffle()

	for door in from_doors:
		for i in range(3):  # try multiple times
			var result = attach_room_to_door(door, new_scene)
			if result:
				return result

	return null


func attach_room_to_door(door, scene):
	var new_room = scene.instantiate()
	add_child(new_room)
	
	print("Trying door: ", door.name)
	print("Overlap: ", is_overlapping(new_room))

	var new_doors = get_doors(new_room)

	for new_door in new_doors:
		# Align forward directions (rotate room)
		var target_rot = door.global_transform.basis.get_euler()
		var new_rot = new_door.transform.basis.get_euler()

		new_room.rotation = target_rot - new_rot + Vector3(0, PI, 0)

		# Move into position
		var offset = new_door.global_transform.origin - new_room.global_transform.origin
		new_room.global_position = door.global_transform.origin - offset

		# OPTIONAL: collision check
		if not is_overlapping(new_room):
			open_doors.erase(door)
			open_doors += get_doors(new_room)
			return { "room": new_room }

	new_room.queue_free()
	return null

func get_doors(room):
	var doors_node = room.get_node_or_null("Doors")
	if doors_node == null:
		push_error("Room missing Doors node: " + room.name)
		return []
	return doors_node.get_children()


func spawn_room(scene, pos, rot):
	var room = scene.instantiate()
	add_child(room)
	room.global_position = pos
	room.rotation.y = rot
	return room

func is_overlapping(room: Node3D) -> bool:
	var aabb1 = get_room_bounds(room)

	for other in placed_rooms:
		if other == room:
			continue

		var aabb2 = get_room_bounds(other)

		if aabb_intersects(aabb1, aabb2):
			return true

	return false

func get_global_aabb(mesh: MeshInstance3D) -> AABB:
	var aabb = mesh.get_aabb()
	return mesh.global_transform * aabb

func get_room_bounds(room: Node3D) -> AABB:
	var bounds = room.get_node_or_null("Bounds")
	if bounds == null:
		push_error("Room missing Bounds node: " + room.name)
		return AABB()

	var shape_node = bounds.get_node("CollisionShape3D")
	var shape = shape_node.shape as BoxShape3D

	var transform = bounds.global_transform

	var extents = shape.size / 2.0
	var origin = transform.origin - extents

	return AABB(origin, shape.size)


func aabb_intersects(a: AABB, b: AABB) -> bool:
	var margin = 0.2  # tweak this

	return (
		a.position.x < b.position.x + b.size.x - margin and
		a.position.x + a.size.x > b.position.x + margin and
		a.position.y < b.position.y + b.size.y - margin and
		a.position.y + a.size.y > b.position.y + margin and
		a.position.z < b.position.z + b.size.z - margin and
		a.position.z + a.size.z > b.position.z + margin
	)
