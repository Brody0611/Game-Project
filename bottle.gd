extends RigidBody3D

@export var sound_radius := 12.0
@export var stun_power := 1

var has_hit := false

func _ready():
	contact_monitor = true
	max_contacts_reported = 5

func _on_body_entered(body):
	if has_hit:
		return
	
	has_hit = true
	
	# 🔊 Emit sound
	emit_sound(global_position, sound_radius)
	
	# 💥 Hit enemy → stun
	if body.is_in_group("enemy"):
		if body.has_method("stagger"):
			body.stagger()
	
	# Optional: delete after hit
	queue_free()

func emit_sound(pos: Vector3, loudness: float):
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for e in enemies:
		if e.has_method("hear_sound"):
			e.hear_sound(pos, loudness)
