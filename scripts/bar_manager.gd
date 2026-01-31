extends Node

@export var recipe_library: RecipeLibrary
@export var docket_scene: PackedScene

# Progression Variables
var current_score: int = 0
var game_difficulty_level: int = 1 # Increases over time
var spawn_rate: float = 10.0 # Seconds between orders

@onready var spawn_timer = $OrderSpawnTimer

func _ready():
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()

func _on_order_spawn_timer_timeout():
	spawn_random_order()
	# Make the game slightly faster every time an order spawns
	spawn_rate = max(3.0, spawn_rate * 0.95) 
	spawn_timer.wait_time = spawn_rate

func spawn_random_order():
	# 1. Filter the library by what the player can currently handle
	var available_drinks = recipe_library.get_recipes_by_difficulty(game_difficulty_level)
	
	if available_drinks.size() > 0:
		var random_drink = available_drinks.pick_random()
		
		# 2. Instance the docket
		var new_docket = docket_scene.instantiate()
		$BarUI/HBoxContainer.add_child(new_docket)
		
		# 3. Setup with resource data
		new_docket.setup(
			random_drink.drink_name, 
			random_drink.ingredients, 
			random_drink.base_time_limit
		)
