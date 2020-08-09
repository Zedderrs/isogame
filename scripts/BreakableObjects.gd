extends StaticBody2D

var type

func _on_CeramicPot_mouse_entered():
	Input.set_default_cursor_shape(1)

func _on_CeramicPot_mouse_exited():
	Input.set_default_cursor_shape(0)
