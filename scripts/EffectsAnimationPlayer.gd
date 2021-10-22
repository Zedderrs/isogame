extends AnimationPlayer


# Declare member variables here. Examples:
onready var game = get_tree().get_root().get_node("Game")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if is_playing():
		if is_start_of_attack(delta):
			game.player.effect.visible = true
		elif is_end_of_attack(delta):
			game.player.effect.visible = false
		if game.player.spell_target:
			if get_current_animation() == game.player.Spell.Lightning:
				lightning_spell(delta)

func lightning_spell(delta):
	if (not game.player.spell_target):
		return
	game.player.effect.position = game.player.spell_target.position - game.player.position
	game.player.effect.position.y -= 64
	if is_point_of_attack(delta):
		game.player.spell_attack()

func is_start_of_attack(delta):
	return (current_animation_position - delta) < 0
	
func is_point_of_attack(delta):
	return ((current_animation_position + delta)/current_animation_length) > 0.75
	
func is_end_of_attack(delta):
	return (current_animation_position + delta) >= current_animation_length
