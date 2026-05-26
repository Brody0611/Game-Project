extends StaticBody3D

var holding := false

func _on_interactable_component_interacted() -> void:
	queue_free()

func throw():
	if  holding == false:
		return null
	
