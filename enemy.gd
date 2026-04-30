extends CharacterBody3D

enum State {
	PATROL,
	SEARCH
}

@export var max_rooms := 3
@export var max_speed := 3.0
@export var acceleration := 6.0
@export var deceleration := 8.0
@export var turn_slowdown := 0.5   # how much to slow on sharp turns (0–1)

var current_speed := 0.0
@export var wait_time := 2.0  # seconds to wait at each point

var wait_timer := 0.0
var is_waiting := false

var current_state = State.PATROL

@export var speed := 3.0

var nav: NavigationAgent3D
var patrol_points: Array[Node3D] = []
var patrol_index := 0

var target_position: Vector3

# ========================
# SETUP
# ========================
func _ready():
	# Create NavigationAgent
	nav = NavigationAgent3D.new()
	add_child(nav)
	
	nav.path_desired_distance = 0.5
	nav.target_desired_distance = 0.5
	
	# Wait until level is generated
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find patrol points
	
	var nodes = get_tree().get_nodes_in_group("patrol_point")

	patrol_points.clear()

	for n in nodes:
		if n is Node3D:
			patrol_points.append(n)
	
		if patrol_points.is_empty():
			print("NO PATROL POINTS FOUND")
			return
	
	# Start at closest point
	#patrol_index = get_closest_patrol_point()
	set_target(patrol_points[patrol_index].global_position)
	
	await get_tree().process_frame
	await get_tree().process_frame

	gather_local_patrol_points()

	if patrol_points.is_empty():
		print("NO PATROL POINTS")
		return

	#patrol_index = get_closest_patrol_point()
	#set_target(patrol_points[patrol_index].global_position)

# ========================
# MAIN LOOP
# ========================
func _physics_process(delta):
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.SEARCH:
			search_state(delta)

# ========================
# PATROL
# ========================
func patrol_state(delta):
	# If waiting, just count down
	if is_waiting:
		wait_timer -= delta
		
		if wait_timer <= 0:
			is_waiting = false
			
			# Move to next point
			patrol_index = (patrol_index + 1) % patrol_points.size()
			set_target(patrol_points[patrol_index].global_position)
		
		return
	
	# Normal movement
	move_to_target(delta)
	
	# If reached point → start waiting
	if reached_target():
		is_waiting = true
		wait_timer = wait_time
		
		# Stop movement while waiting
		velocity = Vector3.ZERO
# ========================
# SEARCH (for sound later)
# ========================
var search_timer := 0.0

func start_search(pos: Vector3):
	current_state = State.SEARCH
	search_timer = 3.0
	set_target(pos)

func search_state(delta):
	move_to_target(delta)
	
	search_timer -= delta
	if search_timer <= 0:
		current_state = State.PATROL

# ========================
# MOVEMENT
# ========================
func set_target(pos: Vector3):
	target_position = pos
	nav.target_position = pos

func move_to_target(delta):
	var next_pos = nav.get_next_path_position()
	var to_next = next_pos - global_position
	
	var direction = to_next.normalized()
	
	# --- DISTANCE SLOWDOWN (approaching target) ---
	var dist_to_target = global_position.distance_to(target_position)
	var target_speed = max_speed
	
	if dist_to_target < 3.0:
		target_speed *= dist_to_target / 3.0  # slow down near target
	
	# --- TURN SLOWDOWN (corners) ---
	var forward = velocity.normalized()
	if velocity.length() > 0.1:
		var dot = forward.dot(direction)  # -1 to 1
		
		if dot < 0.9: # turning
			target_speed *= lerp(turn_slowdown, 1.0, dot)
	
	# --- ACCELERATION / DECELERATION ---
	if current_speed < target_speed:
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, target_speed, deceleration * delta)
	
	# --- APPLY MOVEMENT ---
	velocity = direction * current_speed
	move_and_slide()


func reached_target() -> bool:
	return global_position.distance_to(target_position) < 1.0

# ========================
# HELPERS
# ========================
func gather_local_patrol_points():
	var all_rooms = get_tree().get_nodes_in_group("room")
	
	if all_rooms.is_empty():
		print("No rooms found")
		return
	
	# Sort rooms by distance to enemy
	all_rooms.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	
	# Pick closest rooms
	var selected_rooms = all_rooms.slice(0, max_rooms)
	
	patrol_points.clear()
	
	for room in selected_rooms:
		var points = room.get_tree().get_nodes_in_group("patrol_point")
		
		for p in points:
			# Make sure this patrol point belongs to THIS room
			if room.is_ancestor_of(p):
				patrol_points.append(p)
	
	print("Using patrol points:", patrol_points.size())
	
