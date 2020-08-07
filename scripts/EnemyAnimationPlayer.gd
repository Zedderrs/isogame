extends AnimationPlayer

# Declare member variables here. Examples:
onready var enemy = get_node("../../.")
var damage_dealt

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !enemy.visible: return
	if enemy.is_attacking() && enemy.interrupt_attack:
		if !damage_dealt:
			stop()
		enemy.interrupt_attack = false
	if is_attack_anim() && is_playing() && is_start_of_attack(delta):
		damage_dealt = false
	elif is_attack_anim() && is_playing() && is_point_of_attack(delta) && enemy.target && !damage_dealt:
		enemy.attack()
		damage_dealt = true
	elif is_attack_anim() && is_playing() && is_end_of_attack(delta) && enemy.target:
		damage_dealt = false

func is_start_of_attack(delta):
	return (current_animation_position - delta) < 0
	
func is_point_of_attack(delta):
	return ((current_animation_position + delta)/current_animation_length) > 0.75
	
func is_end_of_attack(delta):
	return (current_animation_position + delta) >= current_animation_length

func is_attack_anim():
	return -1 != current_animation.find('attack')
