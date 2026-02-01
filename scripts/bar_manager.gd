extends Node2D

# --- Configuration & Scenes ---
@export var recipe_library: RecipeLibrary
@export var docket_scene: PackedScene
@export var shift_duration: float = 90.0 

# --- Nodes ---
@onready var docket_container = $BarUI/HBoxContainer
@onready var shaker = $Shaker
@onready var summary_ui = $SummaryLayer/SummaryUI
@onready var timer_label = $ShiftTimerLabel
@onready var spawn_timer = $OrderSpawnTimer
@onready var camera = $Camera2D
@onready var red_flash = $CanvasLayer/RedFlashRect

# --- Gameplay State ---
var score: int = 0
var orders_completed: int = 0
var orders_missed: int = 0
var current_shift: int = 1
var current_difficulty_tier: int = 1 
var time_left: float
var is_shift_active: bool = false
var grabbed_item = null

func _ready():
	# Connect shaker signal
	if shaker:
		shaker.drink_served.connect(_on_drink_served)
	
	# Connect spawn timer
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Connect UI
	if summary_ui:
		summary_ui.next_shift_requested.connect(_start_new_shift)
		summary_ui.hide()
	
	if red_flash:
		red_flash.modulate.a = 0
		
	_start_new_shift()

func _start_new_shift():
	get_tree().paused = false 
	is_shift_active = true
	orders_completed = 0
	orders_missed = 0
	score = 0
	
	current_difficulty_tier = clampi(current_shift, 1, 5)
	spawn_timer.wait_time = max(3.5, 8.0 - (current_shift * 0.5))
	time_left = shift_duration
	
	for child in docket_container.get_children():
		child.queue_free()
	
	if summary_ui:
		summary_ui.hide()
	
	spawn_timer.start()
	_on_spawn_timer_timeout() 
	_show_shift_announcement()

func _show_shift_announcement():
	timer_label.text = "SHIFT " + str(current_shift)
	var t = create_tween()
	timer_label.pivot_offset = timer_label.size / 2
	timer_label.scale = Vector2(2, 2)
	t.tween_property(timer_label, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK)

func _process(delta):
	if is_shift_active:
		time_left -= delta
		_update_timer_display()
		
		# Only look for hovers if we aren't already dragging something
		if grabbed_item == null:
			_handle_hover_highlight()
		
		if time_left <= 0:
			_end_shift()

# --- Selection Manager ---
func _input(event):
	if not is_shift_active: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_grab_logic()
		elif grabbed_item:
			_release_grab()

func _try_grab_logic():
	var mouse_pos = get_global_mouse_position()
	
	# 1. SHAKER PRIORITY: Serve if clicking shaker
	if _is_mouse_over(shaker, mouse_pos):
		if shaker.has_method("serve_drink"):
			shaker.serve_drink()
			return 

	# 2. BOTTLE/ITEM GRAB
	var closest = _find_closest_under_mouse()
	if closest:
		grabbed_item = closest
		# --- CRITICAL: Wake up the bottle script ---
		grabbed_item.dragging = true 
		
		grabbed_item.z_index = 100 
		if grabbed_item.has_method("pick_up"):
			grabbed_item.pick_up()

func _release_grab():
	# --- CRITICAL: Put the bottle back to sleep ---
	grabbed_item.dragging = false
	grabbed_item.z_index = 0
	
	if grabbed_item.has_method("_check_drop"):
		grabbed_item._check_drop() 
	
	grabbed_item = null

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
	if not item: return false
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
	var m_pos = get_global_mouse_position()
	var hovered = _find_closest_under_mouse()
	var shaker_hovered = _is_mouse_over(shaker, m_pos)
	
	shaker.modulate = Color(1.2, 1.2, 1.2) if shaker_hovered else Color.WHITE

	for item in get_tree().get_nodes_in_group("draggables"):
		item.modulate = Color(1.3, 1.3, 1.3) if item == hovered else Color.WHITE

# --- Game Flow & Timer ---
func _update_timer_display():
	var mins = int(time_left) / 60
	var secs = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	
	if time_left < 10:
		timer_label.modulate = Color.RED if int(time_left * 4) % 2 == 0 else Color.WHITE
	else:
		timer_label.modulate = Color.WHITE

func _on_spawn_timer_timeout():
	if not is_shift_active or docket_container.get_child_count() >= 5:
		return
	
	var tier = randi_range(1, current_difficulty_tier)
	var available = recipe_library.get_recipes_by_difficulty(tier)
	if available.is_empty(): available = recipe_library.get_recipes_by_difficulty(1) 
	
	var drink = available.pick_random()
	var new_docket = docket_scene.instantiate()
	docket_container.add_child(new_docket)
	
	var time_mod = max(0.6, 1.0 - (current_shift * 0.05))
	new_docket.setup(drink.drink_name, drink.ingredients, drink.base_time_limit * time_mod)
	new_docket.order_expired.connect(_on_order_expired)

func _on_drink_served(poured_ingredients: Array):
	var target_docket = null
	for docket in docket_container.get_children():
		var recipe = _find_recipe_resource(docket.recipe_data["name"])
		if recipe and _compare_recipes(docket.recipe_data["ingredients"], poured_ingredients, recipe.is_layered):
			target_docket = docket
			_handle_success(target_docket, recipe)
			break
	
	if not target_docket:
		_handle_mistake()

func _handle_success(docket, recipe):
	shaker.show_finished_drink(recipe.icon)
	score += 100 * current_shift 
	orders_completed += 1
	docket.queue_free()

func _handle_mistake():
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(15.0)
	_flash_red_ui()
	score = max(0, score - 20)

func _on_order_expired(docket):
	orders_missed += 1
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(10.0)

func _end_shift():
	is_shift_active = false
	spawn_timer.stop()
	timer_label.text = "CLOSED"
	
	await get_tree().create_timer(1.5).timeout
	
	if summary_ui:
		summary_ui.show()
		# itch.io specific centering fix
		var screen_center = get_viewport().get_visible_rect().size / 2
		summary_ui.global_position = screen_center
		summary_ui.show_summary(score, orders_completed, orders_missed)
	
	current_shift += 1

# --- Utilities ---
func _compare_recipes(needed: Array, provided: Array, is_layered: bool) -> bool:
	if needed.size() != provided.size(): return false
	var n = needed.map(func(s): return s.to_lower())
	var p = provided.map(func(s): return s.to_lower())
	
	if is_layered: return n == p
	n.sort(); p.sort()
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
