extends StaticBody3D

@export var open := false:
	set(v):
		if v != open:
			open = v
			update_shop()

func update_shop():
	if open:
		$MeshInstance3D2.visible = true
	else:
		$MeshInstance3D2.visible = false

func _process(delta: float) -> void:
	$MeshInstance3D.visible = !!$InteractableComponent.get_character_hovered_by_cur_camera()
	if $MeshInstance3D.visible == true:
		print("it bds")

func toggle_open():
	open = !open

func _on_interactable_component_interacted() -> void:
	pass # Replace with function body.
