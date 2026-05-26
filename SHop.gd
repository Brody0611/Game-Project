extends StaticBody3D

@export var open := false:
	set(v):
		if v != open:
			open = v
			update_shop()

func update_shop():
	if open:
		$"../player/Head/Camera3D/Sprite3D".visible = true
		$"../player".visible = true
	else:
		$"../player/Head/Camera3D/Sprite3D".visible = false
		$"../player".visible = true

func _process(delta: float) -> void:
	if $"../player".viewing == false:
		$"../player/Head/Camera3D/Sprite3D".visible = !!$InteractableComponent.get_character_hovered_by_cur_camera()
		

func toggle_open():
	open = !open

func _on_interactable_component_interacted() -> void:
	pass # Replace with function body.
