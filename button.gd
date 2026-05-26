extends Button

func _ready() -> void:
	pressed.connect(func():
		print("CLICK")
	)
