extends AnimatableBody3D

@onready var anim: AnimationPlayer = $AnimationPlayer

@export var open := false:
	set(value):
		if value != open:
			open = value
			update_door()

func _ready():
	update_door()

func update_door():
	if anim == null:
		print("AnimationPlayer not found!")
		return

	if open:
		anim.play("open")
	else:
		anim.play_backwards("open")

func toggle_open():
	open = !open

func _on_interactable_component_interacted() -> void:
	toggle_open()
