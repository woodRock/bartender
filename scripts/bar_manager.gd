extends Node2D

# --- Configuration & Scenes ---
@export var recipe_library: RecipeLibrary
@export var docket_scene: PackedScene
@export var shift_duration: float = 90.0 

# --- Nodes ---
@onready var docket_container = $BarUI/HBoxContainer
@onready var spawn_timer = $OrderSpawnTimer
@onready var shaker = $Shaker
@onready var camera = $Camera2D
@onready var timer_label = $ShiftTimerLabel
@onready var summary_ui = $SummaryLayer/SummaryUI
@onready var red_flash = $CanvasLayer/RedFlashRect

# --- Gameplay State ---
var score: int = 0
var orders_completed: int = 0
var orders_missed: int = 0
var current_difficulty: int = 1
var time_left: float
var is_shift_active: bool = true

# --- Selection & Dragging State ---
var grabbed_item = null

func _ready():
	time_left = shift_duration
	
	# Connect signals
	shaker.drink_served.connect(_on_drink_served)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Initialize UI
	if red_flash:
		red_flash.modulate.a = 0
	
	spawn_timer.start()
	_on_spawn_timer_timeout() # First order

func _process(delta):
	if is_shift_active:
		# 1. Handle Shift Clock
		time_left -= delta
		_update_timer_display()
		
		# 2. Hover Highlight System
		# Only highlight if we aren't already holding something
		if grabbed_item == null:
			_handle_hover_highlight()
		
		if time_left <= 0:
			_end_shift()

# --- Selection Manager (The "Hand" Logic) ---
func _input(event):
	if not is_shift_active: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_grab_closest_item()
		elif grabbed_item:
			_release_grabbed_item()

func _find_closest_under_mouse():
	var mouse_pos = get_global_mouse_position()
	var draggables = get_tree().get_nodes_in_group("draggables")
	
	var closest_item = null
	var min_dist = 99999.0
	
	for item in draggables:
		if _is_mouse_over(item, mouse_pos):
			var dist = mouse_pos.distance_to(item.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_item = item
	return closest_item

func _is_mouse_over(item: Area2D, m_pos: Vector2) -> bool:
	# Convert global mouse pos to local item space
	var local_m_pos = item.to_local(m_pos)
	var shape_node = item.get_node_or_null("CollisionShape2D")
	
	if not shape_node: return false
	
	var shape = shape_node.shape
	if shape is RectangleShape2D:
		return Rect2(-shape.size/2, shape.size).has_point(local_m_pos)
	elif shape is CircleShape2D:
		return local_m_pos.length() < shape.radius
	return false

func _handle_hover_highlight():
	var hovered = _find_closest_under_mouse()
	# Loop through all items and update their color
	for item in get_tree().get_nodes_in_group("draggables"):
		if item == hovered:
			# Values > 1.0 create a "glow" effect if using HDR/Raw colors
			item.modulate = Color(1.4, 1.4, 1.4) 
		else:
			item.modulate = Color.WHITE

func _try_grab_closest_item():
	var closest = _find_closest_under_mouse()
	if closest:
		grabbed_item = closest
		grabbed_item.dragging = true
		grabbed_item.z_index = 100 # Pop to foreground
		
		# Feedback tween when picked up
		var t = create_tween()
		t.tween_property(grabbed_item, "scale", Vector2(1.1, 1.1), 0.1)

func _release_grabbed_item():
	grabbed_item.dragging = false
	grabbed_item.z_index = 0
	grabbed_item._check_drop() # Return to shelf/check shaker
	grabbed_item = null

# --- Order & Game Flow Logic ---
func _update_timer_display():
	var mins = int(time_left) / 60
	var secs = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	
	if time_left < 10:
		timer_label.modulate = Color.RED if int(time_left * 4) % 2 == 0 else Color.WHITE

func _on_spawn_timer_timeout():
	if not is_shift_active or docket_container.get_child_count() >= 5:
		return
		
	var available = recipe_library.get_recipes_by_difficulty(current_difficulty)
	if available.is_empty(): return
	
	var drink = available.pick_random()
	var new_docket = docket_scene.instantiate()
	docket_container.add_child(new_docket)
	new_docket.setup(drink.drink_name, drink.ingredients, drink.base_time_limit)
	new_docket.order_expired.connect(_on_order_expired)

func _on_drink_served(poured_ingredients: Array):
	var match_found = false
	var target_docket = null
	
	for docket in docket_container.get_children():
		if _compare_recipes(docket.recipe_data["ingredients"], poured_ingredients):
			target_docket = docket
			match_found = true
			break
	
	if match_found:
		_handle_success(target_docket)
	else:
		_handle_mistake()

func _handle_success(docket):
	var recipe_res = _find_recipe_resource(docket.recipe_data["name"])
	if recipe_res:
		shaker.show_finished_drink(recipe_res.icon)
	
	score += 100
	orders_completed += 1
	docket.queue_free()
	_check_progression()

func _handle_mistake():
	camera.apply_shake(15.0)
	_flash_red_ui()
	score = max(0, score - 20)

func _on_order_expired(docket):
	orders_missed += 1
	camera.apply_shake(10.0)

func _check_progression():
	if orders_completed % 4 == 0:
		current_difficulty = min(current_difficulty + 1, 5)
		spawn_timer.wait_time = max(4.0, spawn_timer.wait_time - 1.0)

func _end_shift():
	is_shift_active = false
	spawn_timer.stop()
	timer_label.text = "CLOSED"
	
	await get_tree().create_timer(2.0).timeout
	summary_ui.show_summary(score, orders_completed, orders_missed)

# --- Utilities ---
func _compare_recipes(needed: Array, provided: Array) -> bool:
	if needed.size() != provided.size(): return false
	var n = needed.duplicate(); n.sort()
	var p = provided.duplicate(); p.sort()
	return n == p

func _find_recipe_resource(drink_name: String) -> DrinkRecipe:
	for r in recipe_library.all_recipes:
		if r.drink_name == drink_name: return r
	return null

func _flash_red_ui():
	if not red_flash: return
	var t = create_tween()
	red_flash.modulate.a = 0.4
	t.tween_property(red_flash, "modulate:a", 0.0, 0.4)
