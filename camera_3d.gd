extends Camera3D
var mouse = Vector2()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		mouse = event.position
