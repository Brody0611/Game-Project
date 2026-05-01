extends Node3D

@export var start_room: PackedScene
@export var end_room: PackedScene
@export var main_rooms: Array[PackedScene]
@export var branch_rooms: Array[PackedScene]

@export var bottle_scene: PackedScene

@export var main_length := 6
@export var branch_count := 4

var rng := RandomNumberGenerator.new()

var placed_rooms = []
var open_doors = []

var last_main_scene: PackedScene = null

func _ready():
	rng.randomize()

	var start = spawn_room(start_room, Vector3.ZERO, 0)
	placed_rooms.append(start)

	open_doors += get_doors(start)

	generate_main_path(start)
	generate_branches()
	await get_tree().create_timer(0.8).timeout
	$"../NavigationRegion3D".bake_navigation_mesh()
	
	spawn_bottles()
	debug_spawn_points()
	
	
# ---------------- MAIN PATH ----------------

func generate_main_path(current_room):
	var last_room = current_room

	for i in range(main_length):
		var next_scene = get_random_room(main_rooms, last_main_scene)
		last_main_scene = next_scene
		var result = attach_room(last_room, next_scene)

		if result == null:
			continue

		placed_rooms.append(result.room)
		last_room = result.room

	var end = attach_room(last_room, end_room)
	if end:
		placed_rooms.append(end.room)

# ---------------- BRANCHES ----------------

func generate_branches():
	for i in range(branch_count):
		if open_doors.is_empty():
			return

		var door = open_doors.pick_random()
		var room_scene = branch_rooms.pick_random()

		var result = attach_room_to_door(door, room_scene)

		if result:
			placed_rooms.append(result.room)

# ---------------- ATTACH ----------------

func attach_room(from_room, new_scene):
	var from_doors = get_doors(from_room)
	from_doors.shuffle()

	for door in from_doors:
		for i in range(3):
			var result = attach_room_to_door(door, new_scene)
			if result:
				return result

	return null


func attach_room_to_door(door, scene):
	var new_room = scene.instantiate()
	$"../NavigationRegion3D".add_child(new_room)

	var new_doors = get_doors(new_room)

	for new_door in new_doors:

		var door_marker = get_marker(door)
		var new_marker = get_marker(new_door)

		# -------- ROTATION --------
		var target_rot = door_marker.global_transform.basis.get_euler()
		var new_rot = new_marker.transform.basis.get_euler()

		new_room.rotation = target_rot - new_rot + Vector3(0, PI, 0)

		# -------- POSITION --------
		var offset = new_marker.global_transform.origin - new_room.global_transform.origin
		new_room.global_position = door_marker.global_transform.origin - offset

		# -------- OVERLAP CHECK --------
		var from_room = door.get_parent().get_parent()

		if not is_overlapping(new_room, from_room):
			open_doors.erase(door)
			open_doors += get_doors(new_room)

			# REMOVE WALLS (NOW IT ACTUALLY RUNS)
			remove_wall(door)
			remove_wall(new_door)

			return { "room": new_room }

	new_room.queue_free()
	return null

# ---------------- HELPERS ----------------

func get_doors(room):
	var doors_node = room.get_node_or_null("Doors")
	if doors_node == null:
		return []
	return doors_node.get_children()

func get_marker(door: Node3D) -> Node3D:
	return door.get_node("Marker3D")

func spawn_room(scene, pos, rot):
	var room = scene.instantiate()
	add_child(room)
	room.global_position = pos
	room.rotation.y = rot
	return room

# ---------------- OVERLAP ----------------

func is_overlapping(room: Node3D, ignore: Node3D) -> bool:
	var aabb1 = get_room_bounds(room).grow(-0.2)

	for other in placed_rooms:
		if other == room or other == ignore:
			continue

		var aabb2 = get_room_bounds(other).grow(-0.2)

		if aabb1.intersects(aabb2):
			return true

	return false

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

# ---------------- WALLS ----------------

func remove_wall(door: Node3D):
	var wall = door.get_node_or_null("Wall")
	if wall:
		wall.queue_free()

func get_random_room(pool: Array[PackedScene], last_scene: PackedScene) -> PackedScene:
	if pool.is_empty():
		return null

	var valid_rooms = []

	for room in pool:
		if room != last_scene:
			valid_rooms.append(room)

	# If all rooms were filtered out (only 1 type exists), allow fallback
	if valid_rooms.is_empty():
		return pool.pick_random()

	return valid_rooms.pick_random()

func spawn_bottles():
	var points = get_tree().get_nodes_in_group("bottle_spawn")
	
	print("Bottle spawn points found:", points.size())
	
	var spawned := 0
	
	for p in points:
		if randf() < 0.6:
			var bottle = bottle_scene.instantiate()
			add_child(bottle)
			bottle.global_position = p.global_position
			
			spawned += 1
	
	print("Bottles spawned:", spawned)

func debug_spawn_points():
	var points = get_tree().get_nodes_in_group("bottle_spawn")
	
	for p in points:
		var mesh = MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		mesh.scale = Vector3(0.2, 0.2, 0.2)
		mesh.global_position = p.global_position
		
		add_child(mesh)
