extends Node2D

# --- Connections ---
@export var recipe_library: RecipeLibrary
@export var docket_scene: PackedScene

@onready var docket_container = $BarUI/HBoxContainer
@onready var spawn_timer = $OrderSpawnTimer

# --- Gameplay State ---
var score: int = 0
var current_difficulty: int = 1
var orders_completed: int = 0
var starting_wait_time: float = 10.0 

func _ready():
	# 1. Connect the shaker signal (ensure your Shaker node is named 'Shaker')
	$Shaker.drink_served.connect(_on_drink_served)
	
	# 2. Start the game loop
	spawn_timer.wait_time = starting_wait_time
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	# Optional: Spawn first order immediately
	_on_spawn_timer_timeout()

func _on_spawn_timer_timeout():
	# 3. Get a random drink from the library based on current difficulty
	var drink = recipe_library.get_recipes_by_difficulty(current_difficulty).pick_random()
	
	if drink:
		var new_docket = docket_scene.instantiate()
		docket_container.add_child(new_docket)
		new_docket.setup(drink.drink_name, drink.ingredients, drink.base_time_limit)
		
		# Connect expiry signal to handle failure
		new_docket.order_expired.connect(_on_order_expired)

func _on_drink_served(poured_ingredients: Array):
	var match_found = false
	
	for docket in docket_container.get_children():
		# Check if the poured ingredients match this docket's recipe
		if _compare_recipes(docket.recipe_data["ingredients"], poured_ingredients):
			_complete_order(docket)
			match_found = true
			break
	
	if not match_found:
		print("Mistake! That's not what they ordered.")
		# Add visual feedback here (screen shake, red flash)

func _complete_order(docket):
	print("Perfect ", docket.recipe_data["name"], "!")
	score += 100
	orders_completed += 1
	docket.queue_free()
	
	# 4. Difficulty Progression Logic
	if orders_completed % 5 == 0: # Every 5 drinks, get harder
		current_difficulty = min(current_difficulty + 1, 5)
		spawn_timer.wait_time = max(8.0, spawn_timer.wait_time - 0.1)
		print("Difficulty Increased! Level: ", current_difficulty)

func _on_order_expired(docket):
	score = max(0, score - 50)
	print("Customer left. Score: ", score)

func _compare_recipes(needed: Array, provided: Array) -> bool:
	if needed.size() != provided.size(): return false
	var n = needed.duplicate(); n.sort()
	var p = provided.duplicate(); p.sort()
	return n == p
