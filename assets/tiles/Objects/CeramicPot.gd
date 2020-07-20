extends StaticBody2D

func _on_CeramicPot_mouse_entered():
	Input.set_default_cursor_shape(1)
#	targeted = true

func _on_CeramicPot_mouse_exited():
	Input.set_default_cursor_shape(0)
#	targeted = false
