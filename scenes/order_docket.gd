extends PanelContainer

signal order_expired(docket_node)

@onready var drink_label = $VBoxContainer/DrinkLabel
@onready var timer_bar = $VBoxContainer/ProgressBar
@onready var timer = $VBoxContainer/Timer

var recipe_data: Dictionary

func setup(drink_name: String, ingredients: Array, time_limit: float):
	recipe_data = {"name": drink_name, "ingredients": ingredients}
	$VBoxContainer/DrinkLabel.text = drink_name
	
	timer.wait_time = time_limit
	timer_bar.max_value = time_limit
	timer_bar.value = time_limit
	timer.start()

func _process(_delta):
	# Update the progress bar to match the remaining time
	timer_bar.value = timer.time_left

func _on_timer_timeout():
	order_expired.emit(self)
	queue_free() # Remove the docket when time runs out
