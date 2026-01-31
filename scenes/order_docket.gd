extends PanelContainer

signal order_expired(docket_node)

@onready var drink_label = $VBoxContainer/DrinkLabel
@onready var ingredients_label = $VBoxContainer/IngredientsLabel
@onready var timer_bar = $VBoxContainer/ProgressBar
# Ensure this path matches your actual Scene Tree exactly!
@onready var timer = $VBoxContainer/Timer 

var recipe_data: Dictionary

func setup(drink_name: String, ingredients: Array, time_limit: float):
	recipe_data = {"name": drink_name, "ingredients": ingredients}
	
	# Safety check: if nodes aren't ready yet, this avoids 'null' errors
	if not is_inside_tree(): await ready 
	
	drink_label.text = drink_name
	ingredients_label.text = format_ingredients(ingredients)
	
	timer.wait_time = time_limit
	timer_bar.max_value = time_limit
	timer_bar.value = time_limit
	timer.start()

func _process(_delta):
	if timer.time_left > 0:
		timer_bar.value = timer.time_left

func _on_timer_timeout():
	order_expired.emit(self)
	queue_free()

func format_ingredients(ingredients: Array) -> String:
	var list_text = ""
	for item in ingredients:
		list_text += "- " + str(item) + "\n" # str() ensures it doesn't crash if an item isn't a string
	return list_text.strip_edges()
