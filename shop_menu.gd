extends Control


func _on_button1_pressed() -> void:
	$MarginContainer/VBoxContainer.visible = false
	$MarginContainer/VBoxContainer/Button.disabled = true
	$MarginContainer/VBoxContainer/Button2.disabled = true
	$UpgradesVBox.visible = true
	$UpgradesVBox/Button.disabled = false
	$UpgradesVBox/Button2.disabled = false
	$UpgradesVBox/Button3.disabled = false


func _on_button_2_pressed() -> void:
	$MarginContainer/VBoxContainer.visible = false
	$MarginContainer/VBoxContainer/Button.disabled = true
	$MarginContainer/VBoxContainer/Button2.disabled = true
	$UpgradesVBox2.visible = true
	$UpgradesVBox2/Button.disabled = false
	$UpgradesVBox2/Button2.disabled = false
	$UpgradesVBox2/Button3.disabled = false


func _on_back_pressed() -> void:
	$MarginContainer/VBoxContainer.visible = true
	$MarginContainer/VBoxContainer/Button.disabled = false
	$MarginContainer/VBoxContainer/Button2.disabled = false
	$UpgradesVBox.visible = false
	$UpgradesVBox/Button.disabled = true
	$UpgradesVBox/Button2.disabled = true
	$UpgradesVBox/Button3.disabled = false
	$UpgradesVBox2.visible = false
	$UpgradesVBox2/Button.disabled = true
	$UpgradesVBox2/Button2.disabled = true
	$UpgradesVBox2/Button3.disabled = false


func _on_button_3_pressed() -> void:
	_on_back_pressed()
