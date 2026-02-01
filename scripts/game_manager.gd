extends Node
# Inside your GameManager.gd
var current_shift: int = 1
var base_required_drinks: int = 4

func get_shift_requirements() -> int:
	# Difficulty Curve: 4, 6, 8, 10...
	return base_required_drinks + ((current_shift - 1) * 2)

func get_difficulty_multiplier() -> float:
	# Use this to speed up animations or shorten customer patience
	# Shift 1 = 1.0, Shift 2 = 1.1, Shift 3 = 1.2...
	return 1.0 + ((current_shift - 1) * 0.1)

func complete_shift():
	current_shift += 1
	# Trigger any global unlocks here (e.g., new bottles appearing on shelf)
