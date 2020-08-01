extends AnimationPlayer


# Declare member variables here. Examples:
var game
var anim_length
var current_anim_position
var current_anim
var damage_dealt
# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_tree().get_root().get_node("Game")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	anim_length = current_animation_length
	current_anim_position = get_current_animation_position()
	current_anim = get_current_animation()
	if (game.player.is_attacking() || game.player.is_casting()) && game.player.interrupt:
		if !damage_dealt:
			stop()
		game.player.interrupt = false
	if is_attack_anim() && is_playing() && is_start_of_attack(delta):
		damage_dealt = false
	elif is_attack_anim() && is_playing() && is_point_of_attack(delta) && game.player.target && !damage_dealt:
		if game.player.melee: game.player.attack(game.player.target)
		damage_dealt = true
		game.player.interrupt = false
	elif is_attack_anim() && is_playing() && is_end_of_attack(delta) && game.player.target:
		damage_dealt = false

func is_start_of_attack(delta):
	return (current_anim_position - delta) < 0
	
func is_point_of_attack(delta):
	return ((current_anim_position + delta)/anim_length) > 0.75
	
func is_end_of_attack(delta):
	return (current_anim_position + delta) >= anim_length

func is_attack_anim():
	return -1 != current_anim.find('attack') || -1 != current_anim.find('casting')
