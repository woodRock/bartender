extends Camera2D

@export var shake_fade: float = 10.0
var shake_strength: float = 0.0

func _process(delta):
	if shake_strength > 0:
		# Gradually reduce the shake strength over time
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		# Apply random offset based on current strength
		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		offset = Vector2.ZERO

func apply_shake(strength: float):
	shake_strength = strength
