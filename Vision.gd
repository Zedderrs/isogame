extends Area2D

func _on_Area2D_body_entered(body): # reveal all in vision
	body.visible = true
