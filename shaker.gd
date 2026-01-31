extends Area2D

signal drink_served(ingredients)

@onready var label = $Label # Create a Label child to show current mix
var current_mix: Array = []

func add_ingredient(item):
	current_mix.append(item)
	_update_ui()

func _update_ui():
	label.text = "\n".join(current_mix)

func _input_event(_viewport, event, _shape_idx):
	# Click the shaker to "Serve" the drink
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_mix.size() > 0:
			serve()

func serve():
	drink_served.emit(current_mix)
	current_mix.clear()
	label.text = "Empty"

func empty_into_trash():
	current_mix.clear()
	label.text = "Empty"
