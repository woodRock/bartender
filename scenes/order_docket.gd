extends PanelContainer

signal order_expired(docket)

@onready var name_label = $MarginContainer/VBoxContainer/DrinkLabel
@onready var ingredients_label = $MarginContainer/VBoxContainer/IngredientsLabel
@onready var timer_bar = $MarginContainer/VBoxContainer/TimerProgressBar

var recipe_data = {}
var max_time: float
var current_time: float

func setup(d_name: String, ingredients: Array, time_limit: float):
	recipe_data = {"name": d_name, "ingredients": ingredients}
	max_time = time_limit
	current_time = time_limit
	
	# Header styling
	name_label.text = d_name.to_upper()
	
	# Receipt-style list
	var list_text = ""
	for item in ingredients:
		list_text += "• " + item + "\n"
	ingredients_label.text = list_text
	
	if timer_bar:
		timer_bar.max_value = max_time
		timer_bar.value = max_time

func _process(delta):
	current_time -= delta
	if timer_bar:
		timer_bar.value = current_time
	
	# Visual urgency: change bar color
	if current_time < max_time * 0.25:
		timer_bar.modulate = Color.DARK_RED
		
	if current_time <= 0:
		order_expired.emit(self)
		queue_free()
